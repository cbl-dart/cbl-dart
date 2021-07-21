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

  void addBlockingCall(CallbackCall &call);

  bool takeBlockingCall(CallbackCall &call);

 private:
  CallbackRegistry();

  mutable std::mutex mutex_;
  std::vector<const Callback *> callbacks_;
  std::vector<CallbackCall *> blockingCalls_;
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
  void sendRequest(Dart_CObject *request);

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
  CallbackCall(Callback &callback, bool isBlocking = false);

  CallbackCall(Callback &callback,
               const std::function<CallbackResultHandler> &resultHandler)
      : CallbackCall(callback, true) {
    resultHandler_ = &resultHandler;
  };

  ~CallbackCall();

  bool isBlocking() { return receivePort_ != ILLEGAL_PORT; }
  bool hasResultHandler() { return resultHandler_ != nullptr; }
  bool isExecuted() {
    std::scoped_lock lock(mutex_);
    return isExecuted_;
  }
  bool isCompleted() {
    std::scoped_lock lock(mutex_);
    return isCompleted_;
  }

  void execute(Dart_CObject &arguments);
  void complete(Dart_CObject *result);
  void close();

 private:
  static void messageHandler(Dart_Port dest_port_id, Dart_CObject *message);

  void waitForCompletion();
  bool isFailureResult(Dart_CObject *result);

  std::mutex mutex_;
  Callback &callback_;
  const std::function<CallbackResultHandler> *resultHandler_ = nullptr;
  Dart_Port receivePort_ = ILLEGAL_PORT;
  bool isExecuted_ = false;
  bool isCompleted_ = false;
  bool didFail_ = false;
  std::condition_variable completedCv_;
};
