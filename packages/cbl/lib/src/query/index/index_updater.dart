import 'dart:async';

import 'package:meta/meta.dart';

import '../../document.dart';
import 'index_configuration.dart';
import 'query_index.dart';

/// Class for updating a lazy index.
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// Currently, only vector indexes can be lazy
/// ([VectorIndexConfiguration.lazy]).
///
/// {@category Query}
/// {@category Enterprise Edition}
abstract interface class IndexUpdater {
  /// The number of index rows that need to have their indexed value updated.
  int get length;

  /// The result of evaluating the query index's expression at the given
  /// [index].
  ///
  /// [index] must be in the range of 0 to [length] - 1.
  @useResult
  FutureOr<T?> value<T extends Object>(int index);

  /// Sets the [vector] for the [value] at given [index].
  ///
  /// Setting [vector] to `null` means that there is no vector for the value,
  /// and any existing vector will be removed when [finish] is called.
  ///
  /// [index] must be in the range of 0 to [length] - 1.
  FutureOr<void> setVector(int index, List<double>? vector);

  /// Skips setting the vector for the [value] at given the [index].
  ///
  /// The vector will be required to be compute and set again the next time
  /// [QueryIndex.beginUpdate] is called.
  ///
  /// [index] must be in the range of 0 to [length] - 1.
  FutureOr<void> skipVector(int index);

  /// Updates the index with the computed vectors and removes any index rows for
  /// which vector was set to `null`
  ///
  /// If there ara any indexes between 0 and [length] - 1 for which neither
  /// [setVector] nor [skipVector] was called, an exception will be thrown.
  FutureOr<void> finish();
}

/// A [IndexUpdater] with a primarily synchronous API.
///
/// {@category Query}
/// {@category Enterprise Edition}
abstract interface class SyncIndexUpdater
    implements IndexUpdater, ArrayInterface {
  @override
  @useResult
  T? value<T extends Object>(int index);
  @override
  void setVector(int index, List<double>? vector);
  @override
  void skipVector(int index);
  @override
  void finish();
}

/// A [IndexUpdater] with a primarily asynchronous API.
///
/// {@category Query}
/// {@category Enterprise Edition}
abstract interface class AsyncIndexUpdater implements IndexUpdater {
  @override
  @useResult
  Future<T?> value<T extends Object>(int index);
  @override
  Future<void> setVector(int index, List<double>? vector);
  @override
  Future<void> skipVector(int index);
  @override
  Future<void> finish();
}
