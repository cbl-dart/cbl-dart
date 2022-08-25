#pragma once

#include <condition_variable>
#include <functional>
#include <mutex>
#include <vector>

#include "dart/dart_api_dl.h"

namespace CBLDart {

class AsyncCallback;
class AsyncCallbackCall;

// === AsyncCallbackRegistry ==================================================

class AsyncCallbackRegistry {
 public:
  static AsyncCallbackRegistry instance;

  void registerCallback(const AsyncCallback &callback);

  void unregisterCallback(const AsyncCallback &callback);

  bool callbackExists(const AsyncCallback &callback) const;

  void addBlockingCall(AsyncCallbackCall &call);

  bool takeBlockingCall(AsyncCallbackCall &call);

 private:
  AsyncCallbackRegistry();

  mutable std::mutex mutex_;
  std::vector<const AsyncCallback *> callbacks_;
  std::vector<AsyncCallbackCall *> blockingCalls_;
};

// === AsyncCallback ==========================================================

typedef void (*CallbackFinalizer)(void *context);

class AsyncCallback {
 public:
  AsyncCallback(uint32_t id, Dart_Port sendPort, bool debug);

  ~AsyncCallback();

  uint32_t id() { return id_; };

  void setFinalizer(void *context, CallbackFinalizer finalizer);
  void close();

 private:
  friend class AsyncCallbackCall;

  void registerCall(AsyncCallbackCall &call);
  void unregisterCall(AsyncCallbackCall &call);
  bool sendRequest(Dart_CObject *request);
  inline void debugLog(const char *message);

  uint32_t id_;
  bool debug_;
  std::mutex mutex_;
  std::condition_variable cv_;
  bool closed_ = false;
  Dart_Port sendPort_ = ILLEGAL_PORT;
  void *finalizerContext_ = nullptr;
  CallbackFinalizer finalizer_ = nullptr;
  std::vector<AsyncCallbackCall *> activeCalls_;
};

// === AsyncCallbackCall ======================================================

typedef void(CallbackResultHandler)(Dart_CObject *);

class AsyncCallbackCall {
 public:
  AsyncCallbackCall(AsyncCallback &callback, bool isBlocking = false);

  AsyncCallbackCall(AsyncCallback &callback,
                    const std::function<CallbackResultHandler> &resultHandler)
      : AsyncCallbackCall(callback, true) {
    resultHandler_ = &resultHandler;
  };

  ~AsyncCallbackCall();

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

  void waitForCompletion(std::unique_lock<std::mutex> &lock);
  bool isFailureResult(Dart_CObject *result);
  inline void debugLog(const char *message);

  std::mutex mutex_;
  AsyncCallback &callback_;
  const std::function<CallbackResultHandler> *resultHandler_ = nullptr;
  Dart_Port receivePort_ = ILLEGAL_PORT;
  bool isExecuted_ = false;
  bool isCompleted_ = false;
  bool didFail_ = false;
  std::condition_variable completedCv_;
};

}  // namespace CBLDart
