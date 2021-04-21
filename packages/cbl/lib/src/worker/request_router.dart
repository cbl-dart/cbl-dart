import 'dart:async';

import 'worker.dart';

/// The error which is returned to the originator of a [Worker] request if it
/// cannot be handled.
class RequestHandlerNotFound implements Exception {
  RequestHandlerNotFound(WorkerRequest request)
      : message = 'Could not find a handler for the request of type '
            '"${request.runtimeType}"';

  final String message;

  @override
  String toString() => 'RequestHandlerNotFound(message: $message)';
}

/// A handler which responds to requests which have been sent to a [Worker].
///
/// The handler receives the [request] as its argument and returns the
/// response.
typedef WorkerRequestHandler<T extends WorkerRequest<R>, R> = FutureOr<R>
    Function(T request);

/// Middleware which intercepts calls to a [WorkerRequestHandler].
typedef WorkerRequestHandlerMiddleware = FutureOr<Object?> Function(
  WorkerRequest request,
  WorkerRequestHandler<WorkerRequest, Object?> next,
);

/// Error handler to resolve a [WorkerResponse], when a [WorkerRequestHandler]
/// throws.
///
/// If the handler returns `null` the error is rethrown.
typedef ErrorHandler = WorkerResponse? Function(
  Object error,
  StackTrace trace,
);

/// Default [ErrorHandler] which resolves all errors with resolves
/// [WorkerResponse.error].
final defaultErrorHandler =
    (Object error, StackTrace trace) => WorkerResponse.error(error);

/// Returns an [ErrorHandler] which only resolves errors with are a [T] with
/// [WorkerResponse.error].
///
/// Other errors are rethrown.
ErrorHandler rootedErrorHandler<T>() => (error, stackTrace) {
      if (error is T) return WorkerResponse.error(error);
      return null;
    };

/// Router which handles requests to a [Worker] by dispatching them to
/// a [WorkerRequestHandler].
class RequestRouter {
  final _requestHandlers =
      <Type, WorkerRequestHandler<WorkerRequest, Object?>>{};

  final _middlewareChain = <WorkerRequestHandlerMiddleware>[];

  ErrorHandler _errorHandler = defaultErrorHandler;

  /// Adds [handler] to the set of registered handlers.
  void addHandler<T extends WorkerRequest<R>, R>(
    WorkerRequestHandler<T, R> handler,
  ) {
    final requestType = T;

    assert(
      !_requestHandlers.containsKey(requestType),
      'a handler for the same request type ($requestType) has '
      'already been added',
    );

    _requestHandlers[requestType] = (request) => handler(request as T);
  }

  /// Adds [middleware] to the middleware chain.
  ///
  /// Middleware which has been added earlier is called before middleware
  /// which has been added later.
  void addMiddleware(WorkerRequestHandlerMiddleware middleware) {
    _middlewareChain.add(middleware);
  }

  /// Sets the [errorHandler] to resolve a [WorkerResponse] with, when a
  /// [WorkerRequestHandler] throws.
  void setErrorHandler(ErrorHandler errorHandler) {
    _errorHandler = errorHandler;
  }

  /// Handles a request by invoking the [WorkerRequestHandler] registered for
  /// the given [request].
  Future<WorkerResponse> handleRequest(WorkerRequest request) async {
    final handler = _requestHandlers[request.runtimeType];
    if (handler != null) {
      return _invokeHandler(handler, request);
    } else {
      return WorkerResponse.error(RequestHandlerNotFound(request));
    }
  }

  Future<WorkerResponse> _invokeHandler(
    WorkerRequestHandler<WorkerRequest, Object?> handler,
    WorkerRequest request,
  ) async {
    // Make a copy of the middleware chain.
    final middlewareChain = _middlewareChain.toList();

    Future<Object?> invokeWithMiddleware(WorkerRequest request) async {
      // Each middleware in the `middlewareChain` has been called so we finally
      // call the actual handler.
      if (middlewareChain.isEmpty) return handler(request);

      // Pop the next middleware off of the chain of remaining middleware.
      final middleware = middlewareChain.removeAt(0);

      // The handler `middleware` will call if it wants to execute the rest of
      // the middleware chain.
      Future<Object?> next(WorkerRequest request) =>
          invokeWithMiddleware(request);

      return middleware(request, next);
    }

    try {
      final response = await invokeWithMiddleware(request);
      return WorkerResponse.success(response);
    } catch (error, stackTrace) {
      final response = _errorHandler(error, stackTrace);
      if (response != null) return response;

      rethrow;
    }
  }
}
