import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';
import 'package:ffi/ffi.dart';

import 'database.dart';
import 'errors.dart';
import 'fleece.dart';
import 'native_object.dart';
import 'worker/cbl_worker.dart';
import 'resource.dart';

// region Internal API

Document createDocument({
  required Pointer<CBLDocument> pointer,
  required Worker? worker,
  required bool retain,
}) =>
    Document._fromPointer(
      pointer,
      worker: worker,
      retain: retain,
    );

MutableDocument createMutableDocument({
  required Pointer<CBLMutableDocument> pointer,
  required Worker? worker,
  required bool retain,
  required bool isNew,
}) =>
    MutableDocument._fromPointer(
      pointer,
      worker: worker,
      retain: retain,
      isNew: isNew,
    );

// endregion

/// A [Document] is essentially a JSON object with an [id] string that is unique
/// in its database.
class Document extends NativeResource<NativeObject<CBLDocument>> {
  static late final _bindings = CBLBindings.instance.document;

  Document._fromPointer(
    Pointer<CBLDocument> pointer, {
    Worker? worker,
    required bool retain,
  }) : super(worker == null
            ? CblRefCountedObject(
                pointer,
                release: true,
                retain: retain,
              )
            : CblRefCountedWorkerObject(
                pointer,
                worker,
                release: true,
                retain: retain,
              ));

  /// Returns the ID.
  String get id => _bindings.id(native.pointerUnsafe).toDartString();

  /// The revision id, which is a short opaque string that's
  /// guaranteed to be unique to every change made to the document.
  ///
  /// If the document doesn't exist yet, it is `null`.
  String? get revisionId =>
      _bindings.revisionId(native.pointerUnsafe).toNullable()?.toDartString();

  /// Returns the current sequence in the local database.
  ///
  /// This number increases every time the document is saved, and a more
  /// recently saved document will have a greater sequence number than one saved
  /// earlier, so sequences may be used as an abstract 'clock' to tell relative
  /// modification times.
  int get sequence => _bindings.sequence(native.pointerUnsafe);

  /// The properties as a dictionary.
  ///
  /// This lifetime of the returned value is tied to this document. The dict and
  /// its contents must only be used while this Document has not been garbage
  /// collected. Keep a reference to a Document to ensure that it stays alive.
  Dict get properties =>
      Dict.fromPointer(_bindings.properties(native.pointerUnsafe));

  /// The properties as a JSON string.
  String get propertiesAsJson => runArena(() =>
      scoped(_bindings.propertiesAsJson(native.pointerUnsafe)).toDartString());

  /// Deletes this document from the database.
  ///
  /// Deletions are replicated.
  Future<void> delete([
    ConcurrencyControl concurrency = ConcurrencyControl.failOnConflict,
  ]) {
    _debugDocumentHasWorker();
    return (native as WorkerObject<CBLDocument>)
        .execute((pointer) => DeleteDocument(pointer, concurrency));
  }

  /// Purges this document.
  ///
  /// This removes all traces of the document from the database. Purges are not
  /// replicated. If the document is changed on a server, it will be re-created
  /// when pulled.
  Future<void> purge() {
    _debugDocumentHasWorker();
    return (native as WorkerObject<CBLDocument>)
        .execute((pointer) => PurgeDocument(pointer));
  }

  /// {@macro cbl.document.mutableCopy}
  MutableDocument mutableCopy() => MutableDocument.mutableCopy(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Document &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          revisionId == other.revisionId &&
          sequence == other.sequence &&
          properties == other.properties;

  @override
  int get hashCode =>
      id.hashCode ^
      revisionId.hashCode ^
      sequence.hashCode ^
      properties.hashCode;

  @override
  String toString() => 'Document('
      'id: $id, '
      'revisionId: $revisionId, '
      'sequence: $sequence'
      ')';

  void _debugDocumentHasWorker() {
    assert(native is WorkerObject, 'Document has no Worker');
  }
}

/// A [Document] whose [properties] can be changed.
///
/// A mutable document exposes its properties as a mutable dictionary, so you
/// can change them in place and then call [Database.saveDocument] to persist
/// the changes.
class MutableDocument extends Document {
  static late final _bindings = CBLBindings.instance.mutableDocument;

  MutableDocument._fromPointer(
    Pointer<CBLMutableDocument> pointer, {
    Worker? worker,
    required bool retain,
    required this.isNew,
  }) : super._fromPointer(
          pointer.cast(),
          worker: worker,
          retain: retain,
        );

  /// Creates a new, empty document in memory.
  ///
  /// It will not be added to a database until saved.
  factory MutableDocument([String? id]) {
    final pointer = runArena(() => _bindings
        .makeNew(id == null ? nullptr : id.toNativeUtf8().withScoped()));
    return createMutableDocument(
      pointer: pointer,
      worker: null,
      retain: false,
      isNew: true,
    );
  }

  /// {@template cbl.document.mutableCopy}
  /// Creates a new [MutableDocument] instance that refers to the same document
  /// as the original.
  ///
  /// If the original document has unsaved changes, the new one will also start
  /// out with the same changes; but mutating one document thereafter will not
  /// affect the other.
  /// {@endtemplate}
  factory MutableDocument.mutableCopy(Document original) =>
      createMutableDocument(
        pointer: _bindings.mutableCopy(original.native.pointerUnsafe),
        worker: (original.native as WorkerObject).worker,
        retain: false,
        isNew: false,
      );

  late final Pointer<CBLMutableDocument> _mutablePointer =
      native.pointerUnsafe.cast();

  /// A new document has not been saved to the [Database] while an old document
  /// has been pulled ouf the Database.
  final bool isNew;

  /// The properties as a mutable dictionary.
  ///
  /// Other than the [Dict] returned by [Document.properties], this value's
  /// lifetime is not tied to this document.
  @override
  MutableDict get properties => MutableDict.fromPointer(
        _bindings.mutableProperties(_mutablePointer),
        release: true,
        retain: true,
      );

  set properties(MutableDict properties) {
    _bindings.setProperties(
      _mutablePointer,
      properties.native.pointerUnsafe.cast(),
    );
  }

  set propertiesAsJson(String json) {
    runArena(() {
      _bindings
          .setPropertiesAsJSON(
            _mutablePointer,
            json.toNativeUtf8().withScoped(),
            globalError,
          )
          .checkResultAndError();
    });
  }

  @override
  String toString() => 'MutableDocument('
      'id: $id, '
      'revisionId: $revisionId, '
      'sequence: $sequence'
      ')';
}
