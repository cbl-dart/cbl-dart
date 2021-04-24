#include "Callbacks.h"

// === Callback ===============================================================

Callback::Callback(Dart_Handle dartCallback, Dart_Port sendport)
    : sendPort_(sendport) {
  dartCallbackHandle_ = Dart_NewWeakPersistentHandle_DL(
      dartCallback, this, 0, Callback::dartCallbackHandleFinalizer);
}

Callback::~Callback() {}

void Callback::setFinalizer(void *context, CallbackFinalizer finalizer) {
  finalizerContext_ = context;
  finalizer_ = finalizer;
}

void Callback::close() {
  Dart_DeleteWeakPersistentHandle_DL(dartCallbackHandle_);
  runFinalizer();
  delete this;
}

void Callback::runFinalizer() {
  if (finalizer_) {
    finalizer_(finalizerContext_);
  }
}

void Callback::dartCallbackHandleFinalizer(void *dart_callback_data,
                                           void *peer) {
  auto callback = reinterpret_cast<Callback *>(peer);
  callback->runFinalizer();
  delete callback;
}

// === CallbackCall ===========================================================

CallbackCall::CallbackCall(const Callback &callback) : callback_(callback){};

CallbackCall::CallbackCall(
    const Callback &callback,
    const std::function<CallbackResultHandler> &resultHandler)
    : callback_(callback), resultHandler_(&resultHandler) {
  receivePort_ = Dart_NewNativePort_DL("CallbackCall",
                                       &CallbackCall::messageHandler, false);
};

CallbackCall::~CallbackCall() {
  if (receivePort_ != ILLEGAL_PORT) {
    Dart_CloseNativePort_DL(receivePort_);
  }
}

void CallbackCall::execute(Dart_CObject &arguments) {
  // The SendPort to send the result of the callback to.
  // Only necessary if the caller is interested in it.
  Dart_CObject responsePort;
  if (resultHandler_ == nullptr) {
    responsePort.type = Dart_CObject_kNull;
  } else {
    responsePort.type = Dart_CObject_kSendPort;
    responsePort.value.as_send_port.id = receivePort_;
    responsePort.value.as_send_port.origin_id = ILLEGAL_PORT;
  }

  // Pointer to this call, which is sent back by the Dart side in the result
  // message. This is how we get a reference to this call in the message
  // handler. Only necessary if the caller is interested in the result.
  Dart_CObject callPointer;
  if (resultHandler_ == nullptr) {
    callPointer.type = Dart_CObject_kNull;
  } else {
    callPointer.type = Dart_CObject_kInt64;
    callPointer.value.as_int64 = reinterpret_cast<int64_t>(this);
  }

  // The message is sent as an array.
  Dart_CObject *messageValues[] = {&responsePort, &callPointer, &arguments};

  Dart_CObject message;
  message.type = Dart_CObject_kArray;
  message.value.as_array.length = 3;
  message.value.as_array.values = messageValues;

  Dart_PostCObject_DL(callback_.sendPort(), &message);

  // Now wait for the response if the caller is interested.
  if (resultHandler_ != nullptr) {
    std::mutex mutex;
    std::unique_lock lock(mutex);

    while (!completed_) cv_.wait(lock);
  }
}

void CallbackCall::messageHandler(Dart_Port dest_port_id,
                                  Dart_CObject *message) {
  assert(message->type == Dart_CObject_kArray);
  assert(message->value.as_array.length == 2);

  auto callPointer = message->value.as_array.values[0];
  auto result = message->value.as_array.values[1];

  CallbackCall &call = *reinterpret_cast<CallbackCall *>(
      CBLDart_CObject_getIntValueAsInt64(callPointer));

  assert(call.resultHandler_ != nullptr);

  (*call.resultHandler_)(result);

  call.completed_ = true;
  call.cv_.notify_all();
}
