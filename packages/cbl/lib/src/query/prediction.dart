import 'dart:ffi';
import 'dart:isolate';

import '../../cbl.dart';
import '../bindings.dart';
import '../bindings/cblite.dart' as cblite;
import '../bindings/cblitedart.dart' as cblitedart;
import '../document/dictionary.dart';
import '../fleece/containers.dart' as fl;
import '../fleece/encoder.dart';
import '../fleece/integration/integration.dart';
import '../support/edition.dart';

final _bindings = CBLBindings.instance.query;

/// Interface for a machine learning model that can be used in a [Query].
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// Before using a predictive model in a query, it must be registered using
/// [Prediction.registerModel]. The model can be unregistered using
/// [Prediction.unregisterModel].
///
/// To use a predictive model in a query, use the query builder
/// [Function_.prediction] function or the SQL++ `PREDICTION` function.
///
/// ## Example
///
/// The following example shows how to create and use a predictive model that
/// converts a string to uppercase.
///
/// ```dart
/// class UppercaseModel implements PredictiveModel {
///   @override
///   Dictionary? predict(Dictionary input) =>
///       MutableDictionary({'out': input.string('in')!.toUpperCase()});
/// }
/// ```
///
/// Before using the model in a query, it must be registered:
///
/// ```dart main
/// Prediction.registerModel('uppercase', UppercaseModel());
/// ```
///
/// ### Query Builder
///
/// ```dart main
/// final users = db.createCollection('users');
/// await users.saveDocument(MutableDocument({'name': 'Alice'}));
/// final query = const QueryBuilder()
///     .select(
///       SelectResult.expression(
///         Function_.prediction(
///           'uppercase',
///           Expression.dictionary({'in': Expression.property('name')}),
///         ).property('out'),
///       ).as('prediction'),
///     )
///     .from(DataSource.collection(users));
/// final resultSet = await query.execute();
/// final results = await resultSet.allPlainMapResults();
/// // results: [{"prediction": {"out": "ALICE"}}]
/// ```
///
/// ### SQL++
///
/// ```dart main
/// final users = db.createCollection('users');
/// await users.saveDocument(MutableDocument({'name': 'Alice'}));
/// final query = await db.createQuery(
///   '''
/// SELECT PREDICTION(uppercase, {"in": name}, "out") AS prediction
/// FROM users
/// ''',
/// );
/// final resultSet = await query.execute();
/// final results = await resultSet.allPlainMapResults();
/// // results: [{"prediction": "ALICE"}]
/// ```
///
/// {@category Query}
/// {@category Enterprise Edition}
// ignore: one_member_abstracts
abstract interface class PredictiveModel {
  /// Invokes the model with the given [input] dictionary and returns the
  /// prediction result.
  ///
  /// The [input] dictionary corresponds to the input parameter of the query
  /// builder [Function_.prediction] function or the SQL++ `PREDICTION`
  /// function.
  ///
  /// If the model cannot return a result, the prediction callback should return
  /// `null`, which will be evaluated as `MISSING`.
  ///
  /// If the model throws an exception, the exception will be caught and logged
  /// and the prediction will be evaluated as `MISSING`.
  Dictionary? predict(Dictionary input);
}

// ignore: avoid_classes_with_only_static_members
/// Manager for registering and unregistering [PredictiveModel]s.
///
/// {@macro cbl.EncryptionKey.enterpriseFeature}
///
/// {@category Query}
/// {@category Enterprise Edition}
abstract final class Prediction {
  /// Registers a [PredictiveModel] by the given [name].
  ///
  /// Registering a model will keep the current [Isolate] alive until the model
  /// is unregistered again using [unregisterModel].
  ///
  /// If a model is already registered with the given [name], it will be
  /// unregistered before registering the new model.
  ///
  /// Models registered in one isolate are available in all isolates, but
  /// perform their predictions in the isolate where they are registered in. To
  /// offload the prediction work from the main isolate, consider registering
  /// the model in a separate isolate.
  void registerModel(String name, PredictiveModel model);

  /// Unregisters the [PredictiveModel] with the given [name].
  ///
  /// If no model is registered with the given [name], this method does nothing.
  void unregisterModel(String name);
}

final class PredictionImpl implements Prediction {
  @override
  void registerModel(String name, PredictiveModel model) {
    useEnterpriseFeature(EnterpriseFeature.prediction);
    _FfiPredictiveModel(name, model);
  }

  @override
  void unregisterModel(String name) {
    useEnterpriseFeature(EnterpriseFeature.prediction);
    _bindings.unregisterPredictiveModel(name);
  }
}

// ignore: avoid_private_typedef_functions
typedef _CBLPredictionFunctionSync = cblite.FLMutableDict Function(
  cblite.FLDict input,
);
// ignore: avoid_private_typedef_functions
typedef _CBLPredictionFunctionAsync = Void Function(
  cblite.FLDict input,
  cblitedart.CBLDart_Completer completer,
);

class _FfiPredictiveModel implements Finalizable {
  _FfiPredictiveModel(this._name, this._model) {
    final model = _bindings.createPredictiveModel(
      _name,
      _predictionSyncCallable.nativeFunction,
      _predictionAsyncCallable.nativeFunction,
      _unregisteredCallable.nativeFunction,
    );
    _bindings.bindCBLDartPredictiveModelToDartObject(this, model);
  }

  final String _name;
  final PredictiveModel _model;
  late final NativeCallable<_CBLPredictionFunctionSync>
      _predictionSyncCallable = NativeCallable.isolateLocal(_predictionSync);
  late final NativeCallable<_CBLPredictionFunctionAsync>
      _predictionAsyncCallable = NativeCallable.listener(_predictionAsync);
  late final NativeCallable<Void Function()> _unregisteredCallable =
      NativeCallable.listener(_unregistered);

  cblite.FLMutableDict _predictionSync(cblite.FLDict input) {
    try {
      final inputRoot = MRoot.fromContext(
        MContext(data: fl.Dict.fromPointer(input, isRefCounted: false)),
        isMutable: false,
      );

      final outputDict = _model.predict(inputRoot.asNative! as Dictionary);

      if (outputDict == null) {
        return nullptr;
      }

      final encoder = FleeceEncoder();
      (outputDict as DictionaryImpl).encodeTo(encoder);
      final outputData = encoder.finish();

      final outputDoc =
          fl.Doc.fromResultData(outputData, cblite.FLTrust.kFLTrusted);
      final outputMutableDict =
          fl.MutableDict.mutableCopy(outputDoc.root.asDict!);

      // The caller is responsible for releasing the returned value.
      CBLBindings.instance.cbl.FLValue_Retain(outputMutableDict.pointer.cast());

      return outputMutableDict.pointer.cast();
      // ignore: avoid_catches_without_on_clauses
    } catch (error, stackTrace) {
      CBLBindings.instance.logging.logMessage(
        CBLLogDomain.database,
        CBLLogLevel.error,
        'Uncaught exception in predictive model:\n'
        '$_model\n'
        '$error\n'
        '$stackTrace',
      );
      return nullptr;
    }
  }

  void _predictionAsync(
    cblite.FLDict input,
    cblitedart.CBLDart_Completer completer,
  ) {
    final result = _predictionSync(input);
    CBLBindings.instance.base.completeCompleter(completer, result.cast());
  }

  void _unregistered() {
    _predictionSyncCallable.close();
    _predictionAsyncCallable.close();
    _unregisteredCallable.close();
  }
}
