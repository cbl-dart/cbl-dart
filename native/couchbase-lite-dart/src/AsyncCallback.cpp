#include "AsyncCallback.h"

#include <sstream>

#include "Utils.h"

namespace CBLDart {

// === AsyncCallbackRegistry ==================================================

AsyncCallbackRegistry AsyncCallbackRegistry::instance;

void AsyncCallbackRegistry::registerCallback(const AsyncCallback &callback) {
  std::scoped_lock lock(mutex_);
  callbacks_.push_back(&callback);
}

void AsyncCallbackRegistry::unregisterCallback(const AsyncCallback &callback) {
  std::scoped_lock lock(mutex_);
  callbacks_.erase(std::remove(callbacks_.begin(), callbacks_.end(), &callback),
                   callbacks_.end());
}

bool AsyncCallbackRegistry::callbackExists(
    const AsyncCallback &callback) const {
  std::scoped_lock lock(mutex_);
  return std::find(callbacks_.begin(), callbacks_.end(), &callback) !=
         callbacks_.end();
}

void AsyncCallbackRegistry::addBlockingCall(AsyncCallbackCall &call) {
  assert(call.isBlocking());
  std::scoped_lock lock(mutex_);
  blockingCalls_.push_back(&call);
}

bool AsyncCallbackRegistry::takeBlockingCall(AsyncCallbackCall &call) {
  std::scoped_lock lock(mutex_);
  auto position =
      std::find(blockingCalls_.begin(), blockingCalls_.end(), &call);
  if (position != blockingCalls_.end()) {
    blockingCalls_.erase(position);
    return true;
  } else {
    return false;
  }
}

AsyncCallbackRegistry::AsyncCallbackRegistry() {}

// === AsyncCallback ==========================================================

AsyncCallback::AsyncCallback(uint32_t id, Dart_Port sendPort, bool debug)
    : id_(id), debug_(debug), sendPort_(sendPort) {
  assert(sendPort != ILLEGAL_PORT);
  AsyncCallbackRegistry::instance.registerCallback(*this);
}

AsyncCallback::~AsyncCallback() {
  close();
  debugLog("deleted");
}

void AsyncCallback::setFinalizer(void *context, CallbackFinalizer finalizer) {
  debugLog("setFinalizer");
  std::scoped_lock lock(mutex_);
  assert(!closed_);
  finalizerContext_ = context;
  finalizer_ = finalizer;
}

void AsyncCallback::close() {
  {
    std::scoped_lock lock(mutex_);
    if (closed_) {
      return;
    }

    // After this point no new calls can be registered.
    closed_ = true;
  }

  if (finalizer_) {
    finalizer_(finalizerContext_);
    finalizer_ = nullptr;
    finalizerContext_ = nullptr;
  }

  {
    std::scoped_lock lock(mutex_);
    // Close calls which are executing or could be executed.
    for (auto const &call : activeCalls_) {
      call->close();
    }
  }

  // Wait for all active calls to finish.
  std::unique_lock lock(mutex_);
  cv_.wait(lock, [this] { return activeCalls_.empty(); });

  AsyncCallbackRegistry::instance.unregisterCallback(*this);

  debugLog("closed");
}

void AsyncCallback::registerCall(AsyncCallbackCall &call) {
  assert(AsyncCallbackRegistry::instance.callbackExists(*this));

  std::scoped_lock lock(mutex_);
  assert(!closed_);
  activeCalls_.push_back(&call);
}

void AsyncCallback::unregisterCall(AsyncCallbackCall &call) {
  std::scoped_lock lock(mutex_);
  activeCalls_.erase(
      std::remove(activeCalls_.begin(), activeCalls_.end(), &call),
      activeCalls_.end());

  if (closed_ && activeCalls_.empty()) {
    // Notify the `close` method that all calls have been unregistered.
    cv_.notify_one();
  }
}

bool AsyncCallback::sendRequest(Dart_CObject *request) {
  // If the send port and therefore the callback is closed before the request
  // can be sent, this call returns false. This allows us to avoid calling this
  // function under a lock.
  return Dart_PostCObject_DL(sendPort_, request);
}

inline void AsyncCallback::debugLog(const char *message) {
#ifdef DEBUG
  if (debug_) {
    printf("AsyncCallback #%d (native) -> %s\n", id_, message);
  }
#endif
}

// === AsyncCallbackCall ======================================================

static std::string failureResult = "__ASYNC_CALLBACK_FAILED__";

AsyncCallbackCall::AsyncCallbackCall(AsyncCallback &callback, bool isBlocking)
    : callback_(callback) {
  callback_.registerCall(*this);

  if (isBlocking) {
    receivePort_ = Dart_NewNativePort_DL(
        "AsyncCallbackCall", &AsyncCallbackCall::messageHandler, false);
    assert(receivePort_ != ILLEGAL_PORT);
  }
};

AsyncCallbackCall::~AsyncCallbackCall() {
  callback_.unregisterCall(*this);

  if (isBlocking()) {
    auto didCloseReceivePort = Dart_CloseNativePort_DL(receivePort_);
    assert(didCloseReceivePort);
  }
}

void AsyncCallbackCall::execute(Dart_CObject &arguments) {
  std::unique_lock lock(mutex_);

  assert(!isExecuted_);
  isExecuted_ = true;

  if (isCompleted_) {
    // Call was completed early by `close`.
    assert(!hasResultHandler());
    debugLog("not sending request because call is already closed");
    return;
  }

  // The SendPort to signal the return of the callback.
  // Only necessary if the caller is interested in it.
  Dart_CObject responsePort{};
  if (isBlocking()) {
    responsePort.type = Dart_CObject_kSendPort;
    responsePort.value.as_send_port.id = receivePort_;
    responsePort.value.as_send_port.origin_id = ILLEGAL_PORT;
  } else {
    responsePort.type = Dart_CObject_kNull;
  }

  // Pointer to this call, which is sent back by the Dart side in the result
  // response. This is how we get a reference to this call in the response
  // handler. Only necessary if the caller is waiting for the return of the
  // callback.
  Dart_CObject callPointer{};
  CBLDart_CObject_SetPointer(&callPointer, isBlocking() ? this : nullptr);

  // The request is sent as an array.
  Dart_CObject *requestValues[] = {&responsePort, &callPointer, &arguments};

  Dart_CObject request{};
  request.type = Dart_CObject_kArray;
  request.value.as_array.length = 3;
  request.value.as_array.values = requestValues;

  if (isBlocking()) {
    AsyncCallbackRegistry::instance.addBlockingCall(*this);
  }

  auto didSendRequest = callback_.sendRequest(&request);
  if (!didSendRequest) {
    // The request could not be sent because the callback has already been
    // closed.
    debugLog("did not send request because callback is already closed");
    assert(!hasResultHandler());

    if (isBlocking()) {
      // If the request could not be sent, `complete` will never take this call.
      AsyncCallbackRegistry::instance.takeBlockingCall(*this);
    }

    isCompleted_ = true;
    return;
  }

  debugLog("did send request");

  if (isBlocking()) {
    debugLog("waiting for completion");
    waitForCompletion(lock);
  } else {
    isCompleted_ = true;
  }

  debugLog("finished");
}

void AsyncCallbackCall::complete(Dart_CObject *result) {
  assert(result);

  if (!AsyncCallbackRegistry::instance.takeBlockingCall(*this)) {
    // Prevent completing calls which have been completed by `close`.
    return;
  }

  std::scoped_lock lock(mutex_);

  debugLog("completing with result");

  assert(isBlocking());

  didFail_ = isFailureResult(result);

  if (!didFail_ && hasResultHandler()) {
    (*resultHandler_)(result);
  }

  isCompleted_ = true;
  completedCv_.notify_one();
}

void AsyncCallbackCall::close() {
  std::scoped_lock lock(mutex_);

  // Call has not been executed.
  if (!isExecuted_) {
    debugLog("closing call which has not been executed");

    // Mark call as completed and bail out early in `execute`.
    isCompleted_ = true;
    return;
  }

  // Call is waiting for completion.
  if (!isCompleted_) {
    auto didTakeCall = AsyncCallbackRegistry::instance.takeBlockingCall(*this);
    if (!didTakeCall) {
      // If at this point we are not able to take the blocking call,
      // `complete` already did and is just waiting for us to release
      // the lock on this call.
      debugLog("not completing call which will be completed with result");
      return;
    }

    assert(!hasResultHandler());

    debugLog("completing to close call");

    isCompleted_ = true;
    completedCv_.notify_one();
    return;
  }

  // Call has already completed.
  debugLog("did nothing to close call which has already been completed");
}

void AsyncCallbackCall::messageHandler(Dart_Port dest_port_id,
                                       Dart_CObject *response) {
  assert(response->type == Dart_CObject_kArray);
  assert(response->value.as_array.length == 2);

  auto callPointer = response->value.as_array.values[0];
  auto result = response->value.as_array.values[1];

  AsyncCallbackCall &call = *reinterpret_cast<AsyncCallbackCall *>(
      CBLDart_CObject_getIntValueAsInt64(callPointer));

  call.complete(result);
}

void AsyncCallbackCall::waitForCompletion(std::unique_lock<std::mutex> &lock) {
  completedCv_.wait(lock, [this] { return isCompleted_; });

  if (didFail_) {
    debugLog("failed");
    throw std::runtime_error(failureResult);
  }
}

bool AsyncCallbackCall::isFailureResult(Dart_CObject *result) {
  return result->type == Dart_CObject_kString &&
         failureResult == result->value.as_string;
}

inline void AsyncCallbackCall::debugLog(const char *message) {
#ifdef DEBUG
  if (!callback_.debug_) {
    return;
  }

  std::ostringstream stream;
  stream << "Call " << this << " -> " << message;
  auto str = stream.str();
  callback_.debugLog(str.c_str());
#endif
}

}  // namespace CBLDart
