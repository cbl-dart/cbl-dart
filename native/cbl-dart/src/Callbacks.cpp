#include "Callbacks.h"

#include <sstream>

#include "Utils.hh"

namespace CBLDart {

// === CallbackRegistry =======================================================

CallbackRegistry CallbackRegistry::instance;

void CallbackRegistry::registerCallback(const Callback &callback) {
  std::scoped_lock lock(mutex_);
  callbacks_.push_back(&callback);
}

void CallbackRegistry::unregisterCallback(const Callback &callback) {
  std::scoped_lock lock(mutex_);
  callbacks_.erase(std::remove(callbacks_.begin(), callbacks_.end(), &callback),
                   callbacks_.end());
}

bool CallbackRegistry::callbackExists(const Callback &callback) const {
  std::scoped_lock lock(mutex_);
  return std::find(callbacks_.begin(), callbacks_.end(), &callback) !=
         callbacks_.end();
}

void CallbackRegistry::addBlockingCall(CallbackCall &call) {
  assert(call.isBlocking());
  std::scoped_lock lock(mutex_);
  blockingCalls_.push_back(&call);
}

bool CallbackRegistry::takeBlockingCall(CallbackCall &call) {
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

CallbackRegistry::CallbackRegistry() {}

// === Callback ===============================================================

Callback::Callback(uint32_t id, Dart_Handle dartCallback, Dart_Port sendport,
                   bool debug)
    : id_(id), debug_(debug), sendPort_(sendport) {
  dartCallbackHandle_ = Dart_NewWeakPersistentHandle_DL(
      dartCallback, this, 0, Callback::dartCallbackHandleFinalizer);
  assert(dartCallbackHandle_ != nullptr);

  CallbackRegistry::instance.registerCallback(*this);
}

void Callback::setFinalizer(void *context, CallbackFinalizer finalizer) {
  debugLog("setFinalizer");
  std::scoped_lock lock(mutex_);
  assert(!closed_);
  finalizerContext_ = context;
  finalizer_ = finalizer;
}

void Callback::close() {
  {
    std::scoped_lock lock(mutex_);
    assert(!closed_);

    // After this point no new calls can be registered.
    closed_ = true;
  }

  if (dartCallbackHandle_) {
    Dart_DeleteWeakPersistentHandle_DL(dartCallbackHandle_);
    dartCallbackHandle_ = nullptr;
  }

  {
    std::scoped_lock lock(mutex_);
    if (!activeCalls_.empty()) {
      // Close calls which are executing or could be executed.
      for (auto const &call : activeCalls_) {
        call->close();
      }

      // If there are still active calls, wait for them to finish and delete
      // this callback when the last call is done.
      return;
    }
  }

  delete this;
}

void Callback::dartCallbackHandleFinalizer(void *dart_callback_data,
                                           void *peer) {
  auto callback = reinterpret_cast<Callback *>(peer);
  callback->debugLog("closing from Dart finalizer");
  callback->dartCallbackHandle_ = nullptr;
  callback->close();
}

Callback::~Callback() {
  debugLog("deleting");

  assert(activeCalls_.empty());

  CallbackRegistry::instance.unregisterCallback(*this);

  if (finalizer_) {
    finalizer_(finalizerContext_);
  }
}

void Callback::registerCall(CallbackCall &call) {
  assert(CallbackRegistry::instance.callbackExists(*this));

  std::scoped_lock lock(mutex_);
  assert(!closed_);
  activeCalls_.push_back(&call);
}

void Callback::unregisterCall(CallbackCall &call) {
  auto shouldDelete = false;
  {
    std::scoped_lock lock(mutex_);
    activeCalls_.erase(
        std::remove(activeCalls_.begin(), activeCalls_.end(), &call),
        activeCalls_.end());

    if (closed_ && activeCalls_.empty()) {
      // This callback was not deleted in `close` because it still had active
      // calls. Now that is no active call any more, it can be deleted.
      shouldDelete = true;
    }
  }

  if (shouldDelete) {
    delete this;
  }
}

bool Callback::sendRequest(Dart_CObject *request) {
  {
    std::scoped_lock lock(mutex_);
    if (closed_) {
      return false;
    }
  }

  auto didSendRequest = Dart_PostCObject_DL(sendPort_, request);
  assert(didSendRequest);
  return true;
}

inline void Callback::debugLog(const char *message) {
#ifdef DEBUG
  if (debug_) {
    printf("NativeCallback #%d -> %s\n", id_, message);
  }
#endif
}

// === CallbackCall ===========================================================

static std::string failureResult = "__NATIVE_CALLBACK_FAILED__";

CallbackCall::CallbackCall(Callback &callback, bool isBlocking)
    : callback_(callback) {
  callback_.registerCall(*this);

  if (isBlocking) {
    receivePort_ = Dart_NewNativePort_DL("CallbackCall",
                                         &CallbackCall::messageHandler, false);
    assert(receivePort_ != ILLEGAL_PORT);
  }
};

CallbackCall::~CallbackCall() {
  callback_.unregisterCall(*this);

  if (isBlocking()) {
    auto didCloseReceivePort = Dart_CloseNativePort_DL(receivePort_);
    assert(didCloseReceivePort);
  }
}

void CallbackCall::execute(Dart_CObject &arguments) {
  std::scoped_lock lock(mutex_);

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
  Dart_CObject responsePort;
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
  Dart_CObject callPointer;
  CBLDart_CObject_SetPointer(&callPointer, isBlocking() ? this : nullptr);

  // The request is sent as an array.
  Dart_CObject *requestValues[] = {&responsePort, &callPointer, &arguments};

  Dart_CObject request;
  request.type = Dart_CObject_kArray;
  request.value.as_array.length = 3;
  request.value.as_array.values = requestValues;

  if (isBlocking()) {
    CallbackRegistry::instance.addBlockingCall(*this);
  }

  auto didSendRequest = callback_.sendRequest(&request);
  if (!didSendRequest) {
    // The request could not be sent because the callback has already been
    // closed.
    debugLog("did not send request because callback is already closed");
    assert(!hasResultHandler());

    if (isBlocking()) {
      // If the request could not be sent, `complete` will never take this call.
      CallbackRegistry::instance.takeBlockingCall(*this);
    }

    isCompleted_ = true;
    return;
  }

  debugLog("did send request");

  if (isBlocking()) {
    debugLog("waiting for completion");
    waitForCompletion();
  } else {
    isCompleted_ = true;
  }

  debugLog("finished");
}

void CallbackCall::complete(Dart_CObject *result) {
  assert(result);

  if (!CallbackRegistry::instance.takeBlockingCall(*this)) {
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

void CallbackCall::close() {
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
    auto didTakeCall = CallbackRegistry::instance.takeBlockingCall(*this);
    if (!didTakeCall) {
      // If at this point we are not able to take the blocking call,
      // `complete` already did and is just wainting for us to release
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

void CallbackCall::messageHandler(Dart_Port dest_port_id,
                                  Dart_CObject *response) {
  assert(response->type == Dart_CObject_kArray);
  assert(response->value.as_array.length == 2);

  auto callPointer = response->value.as_array.values[0];
  auto result = response->value.as_array.values[1];

  CallbackCall &call = *reinterpret_cast<CallbackCall *>(
      CBLDart_CObject_getIntValueAsInt64(callPointer));

  call.complete(result);
}

void CallbackCall::waitForCompletion() {
  // The mutex has already been locked when this method is called.
  std::unique_lock lock(mutex_, std::adopt_lock);

  completedCv_.wait(lock, [this] { return isCompleted_; });

  if (didFail_) {
    debugLog("failed");
    throw std::runtime_error(failureResult);
  }
}

bool CallbackCall::isFailureResult(Dart_CObject *result) {
  return result->type == Dart_CObject_kString &&
         failureResult == result->value.as_string;
}

inline void CallbackCall::debugLog(const char *message) {
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
