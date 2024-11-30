import 'dart:async';

import 'package:meta/meta.dart';

import '../../database.dart';
import 'index_configuration.dart';
import 'index_updater.dart';

/// An existing index in a [Collection].
///
/// {@category Query}
abstract interface class QueryIndex {
  /// The collection that the index belongs to.
  Collection get collection;

  /// The name of the index.
  String get name;

  /// Begins an update of a lazy index, if the it is not up-to-date.
  ///
  /// {@macro cbl.EncryptionKey.enterpriseFeature}
  ///
  /// Currently, only vector indexes can be lazy
  /// ([VectorIndexConfiguration.lazy]).
  ///
  /// Finds new or updated documents for which the indexed values need to be
  /// (re)computed and returns an [IndexUpdater] for setting the new values.
  ///
  /// [limit] is for setting the max number of documents to be updated.
  @useResult
  FutureOr<IndexUpdater?> beginUpdate({required int limit});
}

/// A [QueryIndex] with a primarily synchronous API.
///
/// {@category Query}
abstract interface class SyncQueryIndex implements QueryIndex {
  @override
  SyncCollection get collection;

  @override
  @useResult
  SyncIndexUpdater? beginUpdate({required int limit});
}

/// A [QueryIndex] with a primarily asynchronous API.
///
/// {@category Query}
abstract interface class AsyncQueryIndex implements QueryIndex {
  @override
  AsyncCollection get collection;

  @override
  @useResult
  Future<AsyncIndexUpdater?> beginUpdate({required int limit});
}
