// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:async';
import 'dart:collection';

import '../fleece/encoder.dart';
import '../fleece/integration/integration.dart';
import '../fleece/shared_strings.dart';
import '../support/encoding.dart';
import '../support/errors.dart';
import '../support/utils.dart';
import 'array.dart';
import 'blob.dart';
import 'common.dart';
import 'dictionary.dart';
import 'fragment.dart';

/// A Couchbase Lite document.
///
/// The [Document] is immutable.
///
/// {@category Document}
abstract class Document implements DictionaryInterface, Iterable<String> {
  /// The document’s id.
  String get id;

  /// The id representing the document’s revision.
  String? get revisionId;

  /// Sequence number of the document in the database.
  ///
  /// This indicates how recently the document has been changed: every time any
  /// document is updated, the database assigns it the next sequential sequence
  /// number. Thus, if a document’s sequence property changes that means it’s
  /// been changed (on-disk); and if one document’s sequence is greater than
  /// another’s, that means it was changed more recently.
  int get sequence;

  /// Returns a mutable copy of the document.
  MutableDocument toMutable();

  /// Returns this document's properties as JSON.
  String toJson();
}

/// A mutable version of [Document].
///
/// {@category Document}
abstract class MutableDocument implements Document, MutableDictionaryInterface {
  /// Creates a new [MutableDocument] with a random UUID, optionally
  /// initialized with [data].
  ///
  /// {@macro cbl.MutableArray.allowedValueTypes}
  factory MutableDocument([Map<String, Object?>? data]) =>
      MutableDelegateDocument(data);

  /// Creates a new [MutableDocument] with a given [id], optionally
  /// initialized with [data].
  ///
  /// {@macro cbl.MutableArray.allowedValueTypes}
  factory MutableDocument.withId(String id, [Map<String, Object?>? data]) =>
      MutableDelegateDocument.withId(id, data);
}

abstract class DocumentDelegate {
  String get id;

  String? get revisionId;

  int get sequence;

  EncodedData get properties;

  set properties(EncodedData value);

  MRoot createMRoot(MContext context, {required bool isMutable}) =>
      MRoot.fromData(
        properties.toFleece(),
        context: context,
        isMutable: isMutable,
      );

  DocumentDelegate toMutable();
}

class NewDocumentDelegate extends DocumentDelegate {
  NewDocumentDelegate([String? id]) : id = id ?? createUuid();

  NewDocumentDelegate.mutableCopy(NewDocumentDelegate delegate)
      : id = delegate.id,
        properties = delegate.properties;

  @override
  final String id;

  @override
  final String? revisionId = null;

  @override
  final sequence = 0;

  @override
  EncodedData properties = _emptyProperties;

  @override
  DocumentDelegate toMutable() => NewDocumentDelegate.mutableCopy(this);

  static late final _emptyProperties = _createEmptyProperties();

  static EncodedData _createEmptyProperties() =>
      EncodedData.fleece((fl.FleeceEncoder()
            ..beginDict(0)
            ..endDict())
          .finish());
}

/// The context for [MCollection]s within a [DelegateDocument].
class DocumentMContext extends MContext implements DatabaseMContext {
  DocumentMContext(this.document);

  /// The [DelegateDocument] to which [MCollection]s with this context belong
  /// to.
  final DelegateDocument document;

  @override
  Database get database => document.database;
}

class DelegateDocument with IterableMixin<String> implements Document {
  DelegateDocument(
    DocumentDelegate delegate, {
    Database? database,
  })  : _delegate = delegate,
        _database = database {
    _setupProperties();
  }

  DocumentDelegate get delegate => _delegate;
  DocumentDelegate _delegate;

  void setDelegate(
    DocumentDelegate delegate, {
    bool updateProperties = true,
  }) {
    if (_delegate == delegate) {
      return;
    }

    _delegate = delegate;

    if (updateProperties) {
      _setupProperties();
    }
  }

  Database get database => _database!;
  Database? _database;

  set database(Database database) {
    if (assertMatchingDatabase(_database, database, 'Document')) {
      _database = database;
    }
  }

  void setProperties(EncodedData properties) {
    delegate.properties = properties;
    _setupProperties();
  }

  FutureOr<EncodedData> getProperties({
    EncodingFormat format = EncodingFormat.fleece,
    bool saveExternalData = false,
  }) {
    final encoder = fl.FleeceEncoder(format: format.toFLEncoderFormat())
      ..extraInfo = FleeceEncoderContext(
        database: database,
        encodeQueryParameter: true,
        saveExternalData: saveExternalData,
      );

    return _root
        .encodeTo(encoder)
        .then((_) => EncodedData(format, encoder.finish()));
  }

  FutureOr<void> syncProperties() => getProperties(saveExternalData: true)
      .then((properties) => delegate.properties = properties);

  final bool _isMutable = false;
  final String _typeName = 'Document';

  void _setupProperties() {
    _root = delegate.createMRoot(DocumentMContext(this), isMutable: _isMutable);
    // ignore: cast_nullable_to_non_nullable
    _properties = _root.asNative as Dictionary;
  }

  late MRoot _root;

  late Dictionary _properties;

  @override
  String get id => _delegate.id;

  @override
  String? get revisionId => _delegate.revisionId;

  @override
  int get sequence => _delegate.sequence;

  @override
  int get length => _properties.length;

  @override
  List<String> get keys => _properties.keys;

  @override
  T? value<T extends Object>(String key) => _properties.value(key);

  @override
  String? string(String key) => _properties.string(key);

  @override
  int integer(String key) => _properties.integer(key);

  @override
  double float(String key) => _properties.float(key);

  @override
  num? number(String key) => _properties.number(key);

  @override
  bool boolean(String key) => _properties.boolean(key);

  @override
  DateTime? date(String key) => _properties.date(key);

  @override
  Blob? blob(String key) => _properties.blob(key);

  @override
  Array? array(String key) => _properties.array(key);

  @override
  Dictionary? dictionary(String key) => _properties.dictionary(key);

  @override
  Fragment operator [](String key) => _properties[key];

  @override
  Map<String, Object?> toPlainMap() => _properties.toPlainMap();

  @override
  MutableDocument toMutable() => MutableDelegateDocument.fromDelegate(
        delegate.toMutable(),
        database: _database,
      );

  @override
  String toJson() => _properties.toJson();

  @override
  Iterator<String> get iterator => _properties.iterator;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DelegateDocument &&
          (_database == other._database ||
              _database?.name == other._database?.name) &&
          id == other.id &&
          _properties == other._properties;

  @override
  int get hashCode =>
      (_database?.name).hashCode ^ id.hashCode ^ _properties.hashCode;

  @override
  String toString() => '$_typeName('
      'id: $id, '
      'revisionId: $revisionId, '
      // ignore: missing_whitespace_between_adjacent_strings
      'sequence: $sequence'
      ')';
}

class MutableDelegateDocument extends DelegateDocument
    implements MutableDocument {
  MutableDelegateDocument([Map<String, Object?>? data])
      : this.fromDelegate(NewDocumentDelegate(), data: data);

  MutableDelegateDocument.withId(String id, [Map<String, Object?>? data])
      : this.fromDelegate(NewDocumentDelegate(id), data: data);

  MutableDelegateDocument.fromDelegate(
    DocumentDelegate delegate, {
    Database? database,
    Map<String, Object?>? data,
  }) : super(delegate, database: database) {
    if (data != null) {
      setData(data);
    }
  }

  @override
  // ignore: overridden_fields
  final _typeName = 'MutableDocument';

  @override
  // ignore: overridden_fields
  final _isMutable = true;

  late MutableDictionary _mutableProperties;

  @override
  void _setupProperties() {
    super._setupProperties();
    _mutableProperties = _properties as MutableDictionary;
  }

  @override
  void setValue(Object? value, {required String key}) =>
      _mutableProperties.setValue(value, key: key);

  @override
  void setString(String? value, {required String key}) =>
      _mutableProperties.setString(value, key: key);

  @override
  void setInteger(int value, {required String key}) =>
      _mutableProperties.setInteger(value, key: key);

  @override
  void setFloat(double value, {required String key}) =>
      _mutableProperties.setFloat(value, key: key);

  @override
  void setNumber(num? value, {required String key}) =>
      _mutableProperties.setNumber(value, key: key);

  @override
  void setBoolean(bool value, {required String key}) =>
      _mutableProperties.setBoolean(value, key: key);

  @override
  void setDate(DateTime? value, {required String key}) =>
      _mutableProperties.setDate(value, key: key);

  @override
  void setBlob(Blob? value, {required String key}) =>
      _mutableProperties.setBlob(value, key: key);

  @override
  void setArray(Array? value, {required String key}) =>
      _mutableProperties.setArray(value, key: key);

  @override
  void setDictionary(Dictionary? value, {required String key}) =>
      _mutableProperties.setDictionary(value, key: key);

  @override
  void setData(Map<String, Object?> data) => _mutableProperties.setData(data);

  @override
  void removeValue(String key) => _mutableProperties.removeValue(key);

  @override
  MutableArray? array(String key) => _mutableProperties.array(key);

  @override
  MutableDictionary? dictionary(String key) =>
      _mutableProperties.dictionary(key);

  @override
  MutableFragment operator [](String key) => _mutableProperties[key];

  @override
  MutableDocument toMutable() => MutableDelegateDocument.fromDelegate(
        delegate.toMutable(),
        database: _database,
        // We make a deep copy of the properties, to include modifications of
        // this document, which have not been synced with the delegate, in the
        // copy.
        data: toPlainMap(),
      );
}
