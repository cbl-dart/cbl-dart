import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../database.dart';
import '../fleece/fleece.dart' as fl;
import '../fleece/integration/integration.dart';
import '../native_object.dart';
import '../resource.dart';
import '../utils.dart';
import 'array.dart';
import 'blob.dart';
import 'dictionary.dart';
import 'fragment.dart';

late final _documentBindings = CBLBindings.instance.document;
late final _mutableDocumentBindings = CBLBindings.instance.mutableDocument;

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
class DocumentMContext extends MContext {
  DocumentMContext(this.document);

  /// The [DocumentImpl] to which [MCollection]s with this context belong to.
  ///
  /// It is important that [MCollection] values have a reference to the
  /// document in their context, because this ensures that the document is not
  /// garbage collected before them. Otherwise the finalizer which
  /// releases the native document would potentially be executed while
  /// a [MCollection], which relies on the documents data, stays alive.
  final DocumentImpl document;
}

class DocumentEncoderContext {
  DocumentEncoderContext(this.document);

  final DocumentImpl document;
}

class DocumentImpl with IterableMixin<String> implements Document {
  DocumentImpl({
    required DatabaseImpl database,
    required Pointer<CBLDocument> doc,
    required bool retain,
    required String debugCreator,
  }) : this._(
          database: database,
          doc: doc,
          retain: retain,
          debugName: 'Document(creator: $debugCreator)',
        );

  DocumentImpl._({
    DatabaseImpl? database,
    required Pointer<CBLDocument> doc,
    required bool retain,
    required String debugName,
  })  : _database = database,
        doc = CblRefCountedObject(
          doc,
          release: true,
          retain: retain,
          debugName: debugName,
        );

  /// The database to which this document belongs.
  ///
  /// Is `null` if the document has not been saved yet.
  DatabaseImpl? get database => _database;
  DatabaseImpl? _database;

  set database(DatabaseImpl? database) {
    if (_database != database) {
      if (_database != null) {
        throw StateError(
          'The document cannot be saved in $database because it already '
          'belongs to a $_database: $this',
        );
      }
      _database = database;
    }
  }

  final NativeObject<CBLDocument> doc;

  late final _root = doc.keepAlive((pointer) => MRoot.fromValue(
        _documentBindings.properties(pointer).cast(),
        context: DocumentMContext(this),
        isMutable: false,
      ));

  late final Dictionary _properties = _root.asNative as Dictionary;

  @override
  String get id => doc.keepAlive(_documentBindings.id);

  @override
  String? get revisionId => doc.keepAlive(_documentBindings.revisionId);

  @override
  int get sequence => doc.keepAlive(_documentBindings.sequence);

  @override
  int get length => _properties.length;

  @override
  List<String> get keys => _properties.keys;

  @override
  Object? value(String key) => _properties.value(key);

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
  Map<String, dynamic> toMap() => _properties.toMap();

  @override
  MutableDocument toMutable() => MutableDocumentImpl(
        doc: doc.keepAlive(_mutableDocumentBindings.mutableCopy),
        // `mutableCopy` returns a new instance with +1 ref count.
        retain: false,
        debugCreator: 'Document.toMutable()',
      );

  @override
  Iterator<String> get iterator => _properties.iterator;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentImpl &&
          id == other.id &&
          revisionId == other.revisionId &&
          sequence == other.sequence &&
          _properties == other._properties;

  @override
  int get hashCode =>
      id.hashCode ^
      revisionId.hashCode ^
      sequence.hashCode ^
      _properties.hashCode;

  final _typeName = 'Document';

  @override
  String toString() => '$_typeName('
      'id: $id, '
      'revisionId: $revisionId, '
      'sequence: $sequence'
      ')';
}

class MutableDocumentImpl extends DocumentImpl implements MutableDocument {
  MutableDocumentImpl({
    DatabaseImpl? database,
    required Pointer<CBLMutableDocument> doc,
    required bool retain,
    required String debugCreator,
  }) : super._(
          database: database,
          doc: doc.cast(),
          retain: retain,
          debugName: 'MutableDocument(creator: $debugCreator)',
        );

  factory MutableDocumentImpl.create({
    String? id,
    Map<String, Object?>? data,
    required String debugCreator,
  }) {
    final result = MutableDocumentImpl(
      doc: _mutableDocumentBindings.createWithID(id),
      // `createWithID` returns a new instance with +1 ref count.
      retain: false,
      debugCreator: debugCreator,
    );

    if (data != null) {
      result.setData(data);
    }

    return result;
  }

  @override
  late final _root = doc.keepAlive((pointer) => MRoot.fromValue(
        _documentBindings.properties(pointer).cast(),
        context: DocumentMContext(this),
        isMutable: true,
      ));

  @override
  late final MutableDictionary _properties =
      _root.asNative as MutableDictionary;

  @override
  MutableArray? array(String key) => _properties.array(key);

  @override
  MutableDictionary? dictionary(String key) => _properties.dictionary(key);

  @override
  MutableFragment operator [](String key) => _properties[key];

  @override
  MutableDocument toMutable() => this;

  @override
  void setValue(Object? value, {required String key}) =>
      _properties.setValue(value, key: key);

  @override
  void setString(String? value, {required String key}) =>
      _properties.setString(value, key: key);

  @override
  void setInteger(int value, {required String key}) =>
      _properties.setInteger(value, key: key);

  @override
  void setFloat(double value, {required String key}) =>
      _properties.setFloat(value, key: key);

  @override
  void setNumber(num? value, {required String key}) =>
      _properties.setNumber(value, key: key);

  @override
  void setBoolean(bool value, {required String key}) =>
      _properties.setBoolean(value, key: key);

  @override
  void setDate(DateTime? value, {required String key}) =>
      _properties.setDate(value, key: key);

  @override
  void setBlob(Blob? value, {required String key}) =>
      _properties.setBlob(value, key: key);

  @override
  void setArray(Array? value, {required String key}) =>
      _properties.setArray(value, key: key);

  @override
  void setDictionary(Dictionary? value, {required String key}) =>
      _properties.setDictionary(value, key: key);

  @override
  void setData(Map<String, Object?> data) => _properties.setData(data);

  @override
  void removeValue(String key) => _properties.removeValue(key);

  /// Encodes `_properties` and sets the result as the new properties of the
  /// native `Document`.
  Future<void> flushProperties() async {
    assert(database != null);
    final encoder = DocumentFleeceEncoder(document: this);
    await _root.encodeTo(encoder);
    final properties = encoder.finishProperties();
    runKeepAlive(() => _mutableDocumentBindings.setProperties(
          doc.pointer.cast(),
          properties.native.pointer.cast(),
        ));
  }

  @override
  final _typeName = 'MutableDocument';
}

class DocumentFleeceEncoder extends fl.FleeceEncoder {
  DocumentFleeceEncoder({required DocumentImpl document})
      : extraInfo = DocumentEncoderContext(document);

  @override
  final DocumentEncoderContext extraInfo;

  final Map<List<Object>, BlobImpl> _blobs = {};

  final _parentCollectionSegments = Queue<Object>();

  Object? _currentCollectionSegment;

  void _beginCollection() {
    _currentCollectionSegment?.let(_parentCollectionSegments.add);
  }

  void _endCollection() {
    if (_parentCollectionSegments.isNotEmpty) {
      _currentCollectionSegment = _parentCollectionSegments.removeLast();
    }
  }

  void _writeKey(String key) {
    _currentCollectionSegment = key;
  }

  void _writeValue() {
    final collectionSegment = _currentCollectionSegment;
    if (collectionSegment is int) {
      _currentCollectionSegment = collectionSegment + 1;
    } else if (collectionSegment is String) {
      _currentCollectionSegment = null;
    }
  }

  void writeBlob(BlobImpl blob) {
    _blobs[[..._parentCollectionSegments, _currentCollectionSegment!]] = blob;
    _writeValue();
    writeNull();
  }

  @override
  void writeArrayValue(Pointer<FLArray> array, int index) {
    _writeValue();
    super.writeArrayValue(array, index);
  }

  @override
  void writeValue(Pointer<FLValue> value) {
    _writeValue();
    super.writeValue(value);
  }

  @override
  void writeNull() {
    _writeValue();
    super.writeNull();
  }

  @override
  void writeBool(bool value) {
    _writeValue();
    super.writeBool(value);
  }

  @override
  void writeInt(int value) {
    _writeValue();
    super.writeInt(value);
  }

  @override
  void writeDouble(double value) {
    _writeValue();
    super.writeDouble(value);
  }

  @override
  void writeString(String value) {
    _writeValue();
    super.writeString(value);
  }

  @override
  void writeData(TypedData value) {
    _writeValue();
    super.writeData(value);
  }

  @override
  void writeJson(String value) {
    _writeValue();
    super.writeJson(value);
  }

  @override
  void beginArray(int reserveLength) {
    _beginCollection();
    _currentCollectionSegment = 0;
    super.beginArray(reserveLength);
  }

  @override
  void endArray() {
    _endCollection();
    super.endArray();
  }

  @override
  void beginDict(int reserveLength) {
    _beginCollection();
    super.beginDict(reserveLength);
  }

  @override
  void writeKey(String key) {
    _writeKey(key);
    super.writeKey(key);
  }

  @override
  void endDict() {
    _endCollection();
    super.endDict();
  }

  @override
  void reset() {
    _blobs.clear();
    _parentCollectionSegments.clear();
    _currentCollectionSegment = null;
    super.reset();
  }

  fl.MutableDict finishProperties() {
    final data = finish();
    final doc = fl.Doc.fromResultData(data, FLTrust.trusted);
    final properties = fl.MutableDict.mutableCopy(doc.root.asDict!);

    if (_blobs.isNotEmpty) {
      _insertBlobs(properties);
    }

    return properties;
  }

  void _insertBlobs(fl.MutableDict properties) {
    for (var entry in _blobs.entries) {
      _insertBlob(properties, entry.key, entry.value);
    }
  }

  void _insertBlob(
    fl.MutableDict properties,
    List<Object> path,
    BlobImpl blob,
  ) {
    fl.Value makeMutable(fl.Value value) {
      final array = value.asArray;
      if (array != null) {
        return fl.MutableArray.mutableCopy(array);
      }
      return fl.MutableDict.mutableCopy(value.asDict!);
    }

    fl.Value parent = properties;
    while (path.isNotEmpty) {
      final segment = path.removeAt(0);
      final isLastSegment = path.isEmpty;

      fl.Value child;
      if (parent is fl.Array) {
        if (isLastSegment) {
          parent[segment as int] = blob;
          break;
        } else {
          parent[segment as int] = child = makeMutable(parent[segment]);
        }
      } else {
        parent = parent as fl.Dict;
        if (isLastSegment) {
          parent[segment as String] = blob;
          break;
        } else {
          parent[segment as String] = child = makeMutable(parent[segment]);
        }
      }
      parent = child;
    }
  }
}
