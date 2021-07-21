#pragma once

#include <condition_variable>
#include <functional>
#include <mutex>
#include <vector>

#include "dart/dart_api_dl.h"

class Callback;
class CallbackCall;

// === CallbackRegistry =======================================================

class CallbackRegistry {
 public:
  static CallbackRegistry instance;

  void registerCallback(const Callback &callback);

  void unregisterCallback(const Callback &callback);

  bool callbackExists(const Callback &callback) const;

 private:
  CallbackRegistry();

  mutable std::mutex mutex_;
  std::vector<const Callback *> callbacks_;
};

// === Callback ===============================================================

typedef void (*CallbackFinalizer)(void *context);

class Callback {
 public:
  Callback(Dart_Handle dartCallback, Dart_Port sendport);

  void setFinalizer(void *context, CallbackFinalizer finalizer);
  void close();

 private:
  friend class CallbackCall;

  void static dartCallbackHandleFinalizer(void *dart_callback_data, void *peer);

  ~Callback();

  void registerCall(CallbackCall &call);
  void unregisterCall(CallbackCall &call);
  void sendRequest(Dart_CObject &request);

  std::mutex mutex_;
  bool closed_ = false;
  Dart_Port sendPort_ = ILLEGAL_PORT;
  void *finalizerContext_ = nullptr;
  CallbackFinalizer finalizer_ = nullptr;
  Dart_WeakPersistentHandle dartCallbackHandle_ = nullptr;
  std::vector<CallbackCall *> activeCalls_;
};

// === CallbackCall ===========================================================

typedef void(CallbackResultHandler)(Dart_CObject *);

class CallbackCall {
 public:
  CallbackCall(Callback &callback, bool waitForReturn = false);

  CallbackCall(Callback &callback,
               const std::function<CallbackResultHandler> &resultHandler)
      : CallbackCall(callback, true) {
    resultHandler_ = &resultHandler;
  };

  ~CallbackCall();

  bool waitsForReturn() { return receivePort_ != ILLEGAL_PORT; }
  bool expectsResult() { return resultHandler_ != nullptr; }
  void execute(Dart_CObject &arguments);

 private:
  friend class Callback;

  static void messageHandler(Dart_Port dest_port_id, Dart_CObject *message);

  void sendRequestAndWaitForReturn(Dart_CObject &request);
  void complete(Dart_CObject *result = nullptr);

  std::mutex mutex_;
  Callback &callback_;
  const std::function<CallbackResultHandler> *resultHandler_ = nullptr;
  Dart_Port receivePort_ = ILLEGAL_PORT;
  bool completed_ = false;
  std::condition_variable *completedCv_ = nullptr;
};
