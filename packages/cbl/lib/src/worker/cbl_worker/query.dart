import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../../query.dart';
import '../request_router.dart';
import '../worker.dart';
import 'shared.dart';

late final _bindings = CBLBindings.instance.query;

extension on QueryLanguage {
  CBLQueryLanguage toCBLQueryLanguage() => CBLQueryLanguage.values[index];
}

class CreateDatabaseQuery extends WorkerRequest<TransferablePointer<CBLQuery>> {
  CreateDatabaseQuery(Pointer<CBLDatabase> db, this.queryString, this.language)
      : db = db.toTransferablePointer();

  final TransferablePointer<CBLDatabase> db;
  final String queryString;
  final QueryLanguage language;
}

TransferablePointer<CBLQuery> createDatabaseQuery(
        CreateDatabaseQuery request) =>
    _bindings
        .create(
          request.db.pointer,
          request.language.toCBLQueryLanguage(),
          request.queryString,
        )
        .toTransferablePointer();

class SetQueryParameters extends WorkerRequest<void> {
  SetQueryParameters(Pointer<CBLQuery> query, Pointer<FLDict> parameters)
      : query = query.toTransferablePointer(),
        parameters = parameters.toTransferablePointer();

  final TransferablePointer<CBLQuery> query;
  final TransferablePointer<FLDict> parameters;
}

void setQueryParameters(SetQueryParameters request) => _bindings.setParameters(
      request.query.pointer,
      request.parameters.pointer,
    );

class GetQueryParameters extends WorkerRequest<TransferablePointer<FLDict>?> {
  GetQueryParameters(Pointer<CBLQuery> query)
      : query = query.toTransferablePointer();

  final TransferablePointer<CBLQuery> query;
}

TransferablePointer<FLDict>? getQueryParameters(GetQueryParameters request) =>
    _bindings.parameters(request.query.pointer).toTransferablePointerOrNull();

class ExplainQuery extends WorkerRequest<String> {
  ExplainQuery(Pointer<CBLQuery> query) : query = query.toTransferablePointer();

  final TransferablePointer<CBLQuery> query;
}

String explainQuery(ExplainQuery request) =>
    _bindings.explain(request.query.pointer);

class ExecuteQuery extends WorkerRequest<TransferablePointer<CBLResultSet>> {
  ExecuteQuery(Pointer<CBLQuery> query) : query = query.toTransferablePointer();

  final TransferablePointer<CBLQuery> query;
}

TransferablePointer<CBLResultSet> executeQuery(ExecuteQuery request) =>
    _bindings.execute(request.query.pointer).toTransferablePointer();

class GetQueryColumnCount extends WorkerRequest<int> {
  GetQueryColumnCount(Pointer<CBLQuery> query)
      : query = query.toTransferablePointer();

  final TransferablePointer<CBLQuery> query;
}

int getQueryColumnCount(GetQueryColumnCount request) =>
    _bindings.columnCount(request.query.pointer);

class GetQueryColumnName extends WorkerRequest<String?> {
  GetQueryColumnName(Pointer<CBLQuery> query, this.columnIndex)
      : query = query.toTransferablePointer();

  final TransferablePointer<CBLQuery> query;
  final int columnIndex;
}

String? getQueryColumnName(GetQueryColumnName request) =>
    _bindings.columnName(request.query.pointer, request.columnIndex);

class AddQueryChangeListener
    extends WorkerRequest<TransferablePointer<CBLListenerToken>> {
  AddQueryChangeListener(Pointer<CBLQuery> query, Pointer<Callback> listener)
      : query = query.toTransferablePointer(),
        listener = listener.toTransferablePointer();

  final TransferablePointer<CBLQuery> query;
  final TransferablePointer<Callback> listener;
}

TransferablePointer<CBLListenerToken> addQueryChangeListener(
        AddQueryChangeListener request) =>
    _bindings
        .addChangeListener(request.query.pointer, request.listener.pointer)
        .toTransferablePointer();

class CopyCurrentQueryResultSet
    extends WorkerRequest<TransferablePointer<CBLResultSet>> {
  CopyCurrentQueryResultSet(
      Pointer<CBLQuery> query, Pointer<CBLListenerToken> listenerToken)
      : query = query.toTransferablePointer(),
        listenerToken = listenerToken.toTransferablePointer();

  final TransferablePointer<CBLQuery> query;
  final TransferablePointer<CBLListenerToken> listenerToken;
}

TransferablePointer<CBLResultSet> copyCurrentQueryResultSet(
        CopyCurrentQueryResultSet request) =>
    _bindings
        .copyCurrentResults(
          request.query.pointer,
          request.listenerToken.pointer,
        )
        .toTransferablePointer();

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
