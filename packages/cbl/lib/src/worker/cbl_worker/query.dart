import 'dart:ffi';

import '../../bindings/bindings.dart';
import '../../errors.dart';
import '../../ffi_utils.dart';
import '../../utils.dart';
import '../request_router.dart';
import 'shared.dart';

late final _bindings = CBLBindings.instance.query;

class CreateDatabaseQuery extends ObjectRequest<int> {
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

class SetQueryParameters extends ObjectRequest<void> {
  SetQueryParameters(int address, this.parametersAddress) : super(address);
  final int parametersAddress;
}

void setQueryParameters(SetQueryParameters request) => _bindings.setParameters(
    request.pointer, request.parametersAddress.toPointer);

class GetQueryParameters extends ObjectRequest<int?> {
  GetQueryParameters(int address) : super(address);
}

int? getQueryParameters(GetQueryParameters request) =>
    _bindings.parameters(request.pointer).addressOrNull;

class ExplainQuery extends ObjectRequest<String> {
  ExplainQuery(int address) : super(address);
}

String explainQuery(ExplainQuery request) {
  _bindings.explain(request.pointer, globalSlice);

  // Caller is responsible for allocated memory of result.
  return globalSlice.toDartStringAndFree();
}

class ExecuteQuery extends ObjectRequest<int> {
  ExecuteQuery(int address) : super(address);
}

int executeQuery(ExecuteQuery request) => _bindings
    .execute(request.pointer, globalError)
    .checkResultAndError()
    .address;

class GetQueryColumnCount extends ObjectRequest<int> {
  GetQueryColumnCount(int address) : super(address);
}

int getQueryColumnCount(GetQueryColumnCount request) =>
    _bindings.columnCount(request.pointer);

class GetQueryColumnName extends ObjectRequest<String> {
  GetQueryColumnName(int address, this.columnIndex) : super(address);
  final int columnIndex;
}

String getQueryColumnName(GetQueryColumnName request) {
  _bindings.columnName(request.pointer, request.columnIndex, globalSlice);
  return globalSlice.ref.toDartString();
}

class AddQueryChangeListener extends ObjectRequest<int> {
  AddQueryChangeListener(int address, this.listenerId) : super(address);
  final int listenerId;
}

int addQueryChangeListener(AddQueryChangeListener request) =>
    _bindings.addChangeListener(request.pointer, request.listenerId).address;

class CopyCurrentQueryResultSet extends ObjectRequest<int> {
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
