import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../../errors.dart';
import '../../fleece.dart';
import '../../utils.dart';
import '../request_router.dart';
import 'shared.dart';

late final _bindings = CBLBindings.instance.query;

class CreateDatabaseQuery extends ObjectRequest<CBLDatabase, int> {
  CreateDatabaseQuery(Pointer<CBLDatabase> db, this.queryString, this.language)
      : super(db);
  final String queryString;
  final QueryLanguage language;
}

int createDatabaseQuery(CreateDatabaseQuery request) => _bindings
    .makeNew(
      request.object,
      request.language.toInt(),
      request.queryString.toNativeUtf8().withScoped(),
      _bindings.globalErrorPosition,
      globalError,
    )
    .let((it) => it == nullptr
        ? throw exceptionFromCBLError(queryString: request.queryString)
        : it.address);

class SetQueryParameters extends ObjectRequest<CBLQuery, void> {
  SetQueryParameters(Pointer<CBLQuery> query, this.parametersAddress)
      : super(query);
  final int parametersAddress;
}

void setQueryParameters(SetQueryParameters request) => _bindings.setParameters(
      request.object,
      request.parametersAddress.toPointer(),
    );

class GetQueryParameters extends ObjectRequest<CBLQuery, int?> {
  GetQueryParameters(Pointer<CBLQuery> query) : super(query);
}

int? getQueryParameters(GetQueryParameters request) =>
    _bindings.parameters(request.object).toAddressOrNull();

class ExplainQuery extends ObjectRequest<CBLQuery, String> {
  ExplainQuery(Pointer<CBLQuery> query) : super(query);
}

String explainQuery(ExplainQuery request) {
  _bindings.explain(request.object, globalSlice);

  // Caller is responsible for allocated memory of result.
  return globalSlice.toDartStringAndFree();
}

class ExecuteQuery extends ObjectRequest<CBLQuery, int> {
  ExecuteQuery(Pointer<CBLQuery> query) : super(query);
}

int executeQuery(ExecuteQuery request) => _bindings
    .execute(request.object, globalError)
    .checkResultAndError()
    .address;

class GetQueryColumnCount extends ObjectRequest<CBLQuery, int> {
  GetQueryColumnCount(Pointer<CBLQuery> query) : super(query);
}

int getQueryColumnCount(GetQueryColumnCount request) =>
    _bindings.columnCount(request.object);

class GetQueryColumnName extends ObjectRequest<CBLQuery, String?> {
  GetQueryColumnName(Pointer<CBLQuery> query, this.columnIndex) : super(query);
  final int columnIndex;
}

String? getQueryColumnName(GetQueryColumnName request) {
  _bindings.columnName(request.object, request.columnIndex, globalSlice);
  return globalSlice.ref.toDartString();
}

class AddQueryChangeListener extends ObjectRequest<CBLQuery, int> {
  AddQueryChangeListener(Pointer<CBLQuery> query, this.listenerAddress)
      : super(query);
  final int listenerAddress;
}

int addQueryChangeListener(AddQueryChangeListener request) => _bindings
    .addChangeListener(
      request.object,
      request.listenerAddress.toPointer(),
    )
    .address;

class CopyCurrentQueryResultSet extends ObjectRequest<CBLQuery, int> {
  CopyCurrentQueryResultSet(Pointer<CBLQuery> query, this.listenerTokenAddress)
      : super(query);
  final int listenerTokenAddress;
}

int copyCurrentQueryResultSet(CopyCurrentQueryResultSet request) => _bindings
    .copyCurrentResults(
      request.object,
      request.listenerTokenAddress.toPointer(),
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
