import 'dart:ffi';

import '../../bindings/bindings.dart';
import '../../errors.dart';
import '../../ffi_utils.dart';
import '../../utils.dart';
import '../worker.dart';
import 'shared.dart';

late final _bindings = CBLBindings.instance.query;

class CreateDatabaseQuery extends ObjectRequest {
  CreateDatabaseQuery(int address, this.queryString, this.language)
      : super(address);
  final String queryString;
  final QueryLanguage language;
}

int createDatabaseQuery(CreateDatabaseQuery request) => _bindings
    .makeNew(
      request.pointer,
      request.language.toInt,
      request.queryString.toNativeUtf8().asScoped,
      _bindings.globalErrorPosition,
      globalError,
    )
    .let((it) => it == nullptr
        ? throw exceptionFromCBLError(queryString: request.queryString)
        : it.address);

class SetQueryParameters extends ObjectRequest {
  SetQueryParameters(int address, this.parametersAddress) : super(address);
  final int parametersAddress;
}

void setQueryParameters(SetQueryParameters request) => _bindings.setParameters(
    request.pointer, request.parametersAddress.toPointer);

class GetQueryParameters extends ObjectRequest {
  GetQueryParameters(int address) : super(address);
}

int? getQueryParameters(GetQueryParameters request) =>
    _bindings.parameters(request.pointer).addressOrNull;

class ExplainQuery extends ObjectRequest {
  ExplainQuery(int address) : super(address);
}

class ExecuteQuery extends ObjectRequest {
  ExecuteQuery(int address) : super(address);
}

int executeQuery(ExecuteQuery request) => _bindings
    .execute(request.pointer, globalError)
    .checkResultAndError()
    .address;

String explainQuery(ExplainQuery request) {
  _bindings.explain(request.pointer, globalSlice);

  // Caller is responsible for allocated memory of result.
  return globalSlice.toUtf8AndFree();
}

class GetQueryColumnCount extends ObjectRequest {
  GetQueryColumnCount(int address) : super(address);
}

int getQueryColumnCount(GetQueryColumnCount request) =>
    _bindings.columnCount(request.pointer);

class GetQueryColumnName extends ObjectRequest {
  GetQueryColumnName(int address, this.columnIndex) : super(address);
  final int columnIndex;
}

String getQueryColumnName(GetQueryColumnName request) {
  _bindings.columnName(request.pointer, request.columnIndex, globalSlice);
  return globalSlice.ref.toUtf8();
}

class AddQueryChangeListener extends ObjectRequest {
  AddQueryChangeListener(int address, this.listenerId) : super(address);
  final int listenerId;
}

int addQueryChangeListener(AddQueryChangeListener request) =>
    _bindings.addChangeListener(request.pointer, request.listenerId).address;

class CopyCurrentQueryResultSet extends ObjectRequest {
  CopyCurrentQueryResultSet(int address, this.listenerTokenAddress)
      : super(address);
  final int listenerTokenAddress;
}

int copyCurrentQueryResultSet(CopyCurrentQueryResultSet request) => _bindings
    .copyCurrentResults(
      request.pointer,
      request.listenerTokenAddress.toPointer,
      globalError,
    )
    .checkResultAndError()
    .address;

void addQueryHandlersToRouter(RequestRouter router) {
  router.addHandler(createDatabaseQuery);
  router.addHandler(setQueryParameters);
  router.addHandler(getQueryParameters);
  router.addHandler(executeQuery);
  router.addHandler(explainQuery);
  router.addHandler(getQueryColumnCount);
  router.addHandler(getQueryColumnName);
  router.addHandler(addQueryChangeListener);
  router.addHandler(copyCurrentQueryResultSet);
}
