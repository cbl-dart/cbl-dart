#include "Callbacks.h"

#include "Utils.hh"

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

CallbackRegistry::CallbackRegistry() {}

// === Callback ===============================================================

Callback::Callback(Dart_Handle dartCallback, Dart_Port sendport)
    : sendPort_(sendport) {
  dartCallbackHandle_ = Dart_NewWeakPersistentHandle_DL(
      dartCallback, this, 0, Callback::dartCallbackHandleFinalizer);

  CallbackRegistry::instance.registerCallback(*this);
}

void Callback::setFinalizer(void *context, CallbackFinalizer finalizer) {
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
      // If there are still active calls let them finish and delete
      // this callback when the last call is done.

      // Complete calls which can be completed without a result. Closing
      // the callback implies that the callback won't respond to calls anymore.
      for (auto const &call : activeCalls_) {
        call->complete();
      }

      return;
    }
  }

  delete this;
}

void Callback::dartCallbackHandleFinalizer(void *dart_callback_data,
                                           void *peer) {
  auto callback = reinterpret_cast<Callback *>(peer);
  callback->dartCallbackHandle_ = nullptr;
  callback->close();
}

Callback::~Callback() {
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

void Callback::sendRequest(Dart_CObject &request) {
  std::scoped_lock lock(mutex_);
  if (!closed_) {
    Dart_PostCObject_DL(sendPort_, &request);
  }
}

// === CallbackCall ===========================================================

CallbackCall::CallbackCall(Callback &callback, bool waitForReturn)
    : callback_(callback) {
  callback_.registerCall(*this);

  if (waitForReturn) {
    receivePort_ = Dart_NewNativePort_DL("CallbackCall",
                                         &CallbackCall::messageHandler, false);
  }
};

CallbackCall::~CallbackCall() {
  callback_.unregisterCall(*this);

  if (receivePort_ != ILLEGAL_PORT) {
    Dart_CloseNativePort_DL(receivePort_);
  }
}

void CallbackCall::execute(Dart_CObject &arguments) {
  // The SendPort to signal the return of the callback.
  // Only necessary if the caller is interested in it.
  Dart_CObject responsePort;
  if (waitsForReturn()) {
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
  CBLDart_CObject_SetPointer(&callPointer, waitsForReturn() ? this : nullptr);

  // The request is sent as an array.
  Dart_CObject *requestValues[] = {&responsePort, &callPointer, &arguments};

  Dart_CObject request;
  request.type = Dart_CObject_kArray;
  request.value.as_array.length = 3;
  request.value.as_array.values = requestValues;

  if (waitsForReturn()) {
    sendRequestAndWaitForReturn(request);
  } else {
    callback_.sendRequest(request);
  }
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

void CallbackCall::sendRequestAndWaitForReturn(Dart_CObject &request) {
  std::unique_lock<std::mutex> lock(mutex_);

  if (completed_) {
    // If the call has been completed early because the callback has been
    // closed don't send the request.
    assert(!expectsResult());
    return;
  }

  std::condition_variable cv;
  completedCv_ = &cv;

  callback_.sendRequest(request);

  cv.wait(lock, [this] { return completed_; });

  completedCv_ = nullptr;
}

void CallbackCall::complete(Dart_CObject *result) {
  std::scoped_lock lock(mutex_);

  assert(result || !expectsResult());

  if (completed_) {
    // If the call has been completed early because the callback has been
    // closed don't send the request.
    assert(!expectsResult());
    return;
  }

  if (expectsResult()) {
    (*resultHandler_)(result);
  }

  completed_ = true;

  if (completedCv_) {
    completedCv_->notify_one();
  }
}
