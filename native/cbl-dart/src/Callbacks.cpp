#include "Callbacks.h"

CallbackIsolate *&CallbackIsolate::getForCallbackId(CallbackId callbackId) {
  assert(callbackId != NULL_CALLBACK);

  const std::shared_lock lock(isolatesByCallback_mutex);
  return isolatesByCallback[callbackId];
}

CallbackIsolate::CallbackIsolate(Dart_Handle handle, Dart_Port sendPort)
    : sendPort_(sendPort) {
  Dart_NewFinalizableHandle_DL(handle, this, 0, CallbackIsolate::finalizer);
};

Dart_Port CallbackIsolate::sendPort() { return sendPort_; };

// This method is called when the Isolate which this instance was created by.
void CallbackIsolate::finalizer(void *dart_callback_data, void *peer) {
  auto &self = *reinterpret_cast<CallbackIsolate *>(peer);

  // Clean up the callbacks which have not been unregistered before the Isolate
  // died.
  for (const auto callbackId : self.callbackIds) {
    {
      const std::unique_lock lock(isolatesByCallback_mutex);
      isolatesByCallback.erase(callbackId);
    }

    // Run finalizer if it exists.
    self.removeFinalizer(callbackId, true);
  }

  delete &self;
}

CallbackId CallbackIsolate::registerCallback() {
  auto callbackId = createCallbackId();

  {
    const std::unique_lock lock(isolatesByCallback_mutex);
    isolatesByCallback[callbackId] = this;
  }

  callbackIds.push_back(callbackId);

  return callbackId;
}

void CallbackIsolate::unregisterCallback(CallbackId callbackId,
                                         bool runFinalizer) {
  assert(callbackId != ILLEGAL_PORT);

  {
    const std::unique_lock lock(isolatesByCallback_mutex);
    isolatesByCallback.erase(callbackId);
  }

  auto position = std::find(callbackIds.begin(), callbackIds.end(), callbackId);
  callbackIds.erase(position);

  removeFinalizer(callbackId, runFinalizer);
}

void CallbackIsolate::setCallbackFinalizer(CallbackId callbackId, void *context,
                                           CallbackFinalizer finalizer) {
  // We are not synchronizing access here because Isolates are single threaded
  // and the only callers of this api.
  assert(callbackFinalizers[callbackId] == nullptr);
  callbackFinalizers[callbackId] = new std::pair(finalizer, context);
}

void CallbackIsolate::removeCallbackFinalizer(CallbackId callbackId) {
  removeFinalizer(callbackId, false);
}

std::atomic<CallbackId> CallbackIsolate::nextCallbackId = 1;

std::map<CallbackId, CallbackIsolate *> CallbackIsolate::isolatesByCallback;
std::shared_mutex CallbackIsolate::isolatesByCallback_mutex;

CallbackId CallbackIsolate::createCallbackId() {
  return nextCallbackId.fetch_add(1);
}

void CallbackIsolate::removeFinalizer(CallbackId callbackId,
                                      bool runFinalizer) {
  auto finalizer = callbackFinalizers[callbackId];
  if (finalizer) {
    if (runFinalizer) finalizer->first(callbackId, finalizer->second);

    callbackFinalizers.erase(callbackId);
    delete finalizer;
  }
}

typedef void(CallbackResultHandler)(Dart_CObject *);

CallbackCall::CallbackCall(){};

CallbackCall::CallbackCall(
    const std::function<CallbackResultHandler> &resultHandler)
    : resultHandler(&resultHandler) {
  receivePort = Dart_NewNativePort_DL("CallbackCall",
                                      &CallbackCall::messageHandler, false);
};

CallbackCall::~CallbackCall() {
  if (receivePort != ILLEGAL_PORT) {
    Dart_CloseNativePort_DL(receivePort);
  }
}

void CallbackCall::execute(CallbackId callbackId, Dart_CObject *arguments) {
  assert(callbackId != ILLEGAL_PORT);

  auto isolate = CallbackIsolate::getForCallbackId(callbackId);
  assert(isolate != nullptr);

  // Pointer to the callback to invoke, through which the Dart side can identify
  // the callback.
  Dart_CObject callbackId_;
  callbackId_.type = Dart_CObject_kInt64;
  callbackId_.value.as_int64 = callbackId;

  // The SendPort to send the result of the callback to.
  // Only necessary if the caller is interested in it.
  Dart_CObject responsePort;
  if (resultHandler == nullptr) {
    responsePort.type = Dart_CObject_kNull;
  } else {
    responsePort.type = Dart_CObject_kSendPort;
    responsePort.value.as_send_port.id = receivePort;
    responsePort.value.as_send_port.origin_id = ILLEGAL_PORT;
  }

  // Pointer to this call, which is sent back by the Dart side in the result
  // message. This is how we get a reference to this call in the message
  // handler. Only necessary if the caller is interested in the result.
  Dart_CObject callPointer;
  if (resultHandler == nullptr) {
    callPointer.type = Dart_CObject_kNull;
  } else {
    callPointer.type = Dart_CObject_kInt64;
    callPointer.value.as_int64 = reinterpret_cast<int64_t>(this);
  }

  // The message is sent as an array.
  Dart_CObject *messageValues[] = {&callbackId_, &responsePort, &callPointer,
                                   arguments};

  Dart_CObject message;
  message.type = Dart_CObject_kArray;
  message.value.as_array.length = 4;
  message.value.as_array.values = messageValues;

  Dart_PostCObject_DL(isolate->sendPort(), &message);

  // Now wait for the response if the caller is interested.
  if (resultHandler != nullptr) {
    std::mutex mutex;
    std::unique_lock lock(mutex);

    while (!completed) cv.wait(lock);
  }
}

void CallbackCall::messageHandler(Dart_Port dest_port_id,
                                  Dart_CObject *message) {
  auto callPointer = message->value.as_array.values[0]->value.as_int64;
  CallbackCall &call = *reinterpret_cast<CallbackCall *>(callPointer);

  auto result = message->value.as_array.values[1];

  assert(call.resultHandler != nullptr);

  (*call.resultHandler)(result);

  call.completed = true;
  call.cv.notify_all();
}
