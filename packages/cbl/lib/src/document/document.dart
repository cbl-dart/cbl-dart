import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database/database.dart';
import '../fleece/fleece.dart' as fl;
import '../fleece/integration/integration.dart';
import '../support/ffi.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import '../support/utils.dart';
import 'array.dart';
import 'blob.dart';
import 'common.dart';
import 'dictionary.dart';
import 'fragment.dart';

late final _documentBindings = cblBindings.document;
late final _mutableDocumentBindings = cblBindings.mutableDocument;

/// A Couchbase Lite document.
///
/// The [Document] is immutable.
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
}

/// A mutable version of [Document].
abstract class MutableDocument implements Document, MutableDictionaryInterface {
  /// Creates a new [MutableDocument] with a random UUID, optionally
  /// initialized with [data].
  ///
  /// {@macro cbl.MutableArray.allowedValueTypes}
  factory MutableDocument([Map<String, Object?>? data]) =>
      MutableDocumentImpl.create(data: data, debugCreator: 'MutableDocument()');

  /// Creates a new [MutableDocument] with a given [id], optionally
  /// initialized with [data].
  ///
  /// {@macro cbl.MutableArray.allowedValueTypes}
  factory MutableDocument.withId(String id, [Map<String, Object?>? data]) =>
      MutableDocumentImpl.create(
        id: id,
        data: data,
        debugCreator: 'MutableDocument.withId()',
      );
}

/// The context for [MCollection]s within a [DocumentImpl].
class DocumentMContext extends MContext implements DatabaseMContext {
  DocumentMContext(this.document);

  /// The [DocumentImpl] to which [MCollection]s with this context belong to.
  final DocumentMixin document;

  @override
  Database get database => document.database!;
}

mixin DocumentMixin implements Document {
  final bool _isMutable = false;
  final String _typeName = 'Document';

  Database? get database => _database;
  Database? _database;

  set database(Database? database) {
    if (_database != database) {
      if (_database != null) {
        throw StateError(
          'The document cannot be used with  $database because it already '
          'belongs to $_database: $this',
        );
      }
      _database = database;
    }
  }

  void setPropertiesFromData(Uint8List data) {
    _root = MRoot.fromData(
      data,
      context: DocumentMContext(this),
      isMutable: _isMutable,
    );
    _properties = _root.asNative as Dictionary;
  }

  void setPropertiesFromDict(Pointer<FLDict> dict) {
    _root = MRoot.fromValue(
      dict.cast(),
      context: DocumentMContext(this),
      isMutable: _isMutable,
    );
    _properties = _root.asNative as Dictionary;
  }

  late MRoot _root;

  late Dictionary _properties;

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
  Iterator<String> get iterator => _properties.iterator;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentMixin &&
          id == other.id &&
          (!_isMutable && !other._isMutable
              ? revisionId == other.revisionId
              : _properties == other._properties);

  @override
  int get hashCode =>
      id.hashCode ^ (!_isMutable ? revisionId.hashCode : _properties.hashCode);

  @override
  String toString() => '$_typeName('
      'id: $id, '
      'revisionId: $revisionId'
      ')';
}

mixin MutableDocumentMixin on DocumentMixin implements MutableDocument {
  @override
  final _typeName = 'MutableDocument';

  @override
  final _isMutable = true;

  late MutableDictionary _mutableProperties;

  @override
  void setPropertiesFromData(Uint8List data) {
    super.setPropertiesFromData(data);
    _mutableProperties = _properties as MutableDictionary;
  }

  @override
  void setPropertiesFromDict(Pointer<FLDict> dict) {
    super.setPropertiesFromDict(dict);
    _mutableProperties = _properties as MutableDictionary;
  }

  SliceResult encodeProperties() {
    assert(database != null);
    final encoder = fl.FleeceEncoder();
    encoder.extraInfo = FleeceEncoderContext(
      database: database,
      encodeQueryParameter: true,
    );
    final encodeToFuture = _root.encodeTo(encoder);
    assert(encodeToFuture is! Future);
    return encoder.finish();
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
  MutableDocument toMutable() => this;
}

class DocumentImpl
    with
        IterableMixin<String>,
        NativeResourceMixin<CBLDocument>,
        DocumentMixin {
  DocumentImpl({
    required FfiDatabase database,
    required Pointer<CBLDocument> doc,
    bool adopt = true,
    required String debugCreator,
  }) : this._(
          database: database,
          doc: doc,
          adopt: adopt,
          debugName: 'Document(creator: $debugCreator)',
        );

  DocumentImpl._({
    FfiDatabase? database,
    required Pointer<CBLDocument> doc,
    required bool adopt,
    required String debugName,
  }) : native = CblObject(
          doc,
          adopt: adopt,
          debugName: debugName,
        ) {
    this.database = database;
    _loadProperties();
  }

  @override
  NativeObject<CBLDocument> native;

  @override
  String get id => native.call(_documentBindings.id);

  @override
  String? get revisionId => native.call(_documentBindings.revisionId);

  @override
  int get sequence => native.call(_documentBindings.sequence);

  @override
  MutableDocument toMutable() => MutableDocumentImpl(
        doc: native.call(_mutableDocumentBindings.mutableCopy),
        debugCreator: 'Document.toMutable()',
      );

  void _replaceNative(NativeObject<CBLDocument> native) {
    this.native = native;
    _loadProperties();
  }

  void _loadProperties() {
    setPropertiesFromDict(native.call(_documentBindings.properties));
  }
}

class MutableDocumentImpl extends DocumentImpl with MutableDocumentMixin {
  MutableDocumentImpl({
    FfiDatabase? database,
    required Pointer<CBLMutableDocument> doc,
    bool adopt = true,
    required String debugCreator,
  }) : super._(
          database: database,
          doc: doc.cast(),
          adopt: adopt,
          debugName: 'MutableDocument(creator: $debugCreator)',
        );

  factory MutableDocumentImpl.create({
    String? id,
    Map<String, Object?>? data,
    required String debugCreator,
  }) {
    id ??= createUuid();

    final result = MutableDocumentImpl(
      doc: _mutableDocumentBindings.createWithID(id),
      debugCreator: debugCreator,
    );

    if (data != null) {
      result.setData(data);
    }

    return result;
  }

  void replaceNativeFrom(DocumentImpl document) {
    _replaceNative(CblObject(
      document.native.call(_mutableDocumentBindings.mutableCopy).cast(),
      debugName: 'MutableDocument.replaceNativeFrom()',
    ));
  }

  /// Encodes `_properties` and sets the result as the new properties of the
  /// native `Document`.
  void flushProperties() {
    _writePropertiesFromData(encodeProperties().asUint8List());
  }

  void _writePropertiesFromData(Uint8List data) {
    final doc = fl.Doc.fromResultData(data, FLTrust.trusted);
    final dict = fl.MutableDict.mutableCopy(doc.root.asDict!);
    runNativeCalls(() => _mutableDocumentBindings.setProperties(
          native.pointer.cast(),
          dict.native.pointer.cast(),
        ));
  }
}
