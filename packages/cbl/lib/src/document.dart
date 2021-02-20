import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'bindings/bindings.dart';
import 'database.dart';
import 'errors.dart';
import 'ffi_utils.dart';
import 'fleece.dart';
import 'worker/cbl_worker.dart';

// region Internal API

Document createDocument({
  required Pointer<Void> pointer,
  Worker? worker,
  bool? retain,
}) =>
    Document._(pointer, worker, retain);

MutableDocument createMutableDocument({
  required Pointer<Void> pointer,
  Worker? worker,
  bool? retain,
  bool isNew = false,
}) =>
    MutableDocument._(pointer, worker, retain, isNew);

extension InternalDocumentExt on Document {
  Pointer<Void> get pointer => _pointer;
}

// endregion

/// A [Document] is essentially a JSON object with an [id] string that is unique
/// in its database.
class Document {
  static late final _bindings = CBLBindings.instance.document;

  Document._(
    this._pointer,
    this._worker,
    bool? retain,
  ) {
    CBLBindings.instance.base
        .bindCBLRefCountedToDartObject(this, _pointer, (retain ?? false).toInt);
  }

  final Pointer<Void> _pointer;

  final Worker? _worker;

  /// Returns the ID.
  String get id => _bindings.id(_pointer).toDartString();

  /// Returns the current sequence in the local database.
  ///
  /// This number increases every time the document is saved, and a more
  /// recently saved document will have a greater sequence number than one saved
  /// earlier, so sequences may be used as an abstract 'clock' to tell relative
  /// modification times.
  int get sequence => _bindings.sequence(_pointer);

  /// The properties as a dictionary.
  ///
  /// This lifetime of the returned value is tied to this document. The dict and
  /// its contents must only be used while this Document has not been garbage
  /// collected. Keep a reference to a Document to ensure that it stays alive.
  Dict get properties => Dict.fromPointer(_bindings.properties(_pointer));

  /// The properties as a JSON string.
  String get propertiesAsJson => runArena(
      () => scoped(_bindings.propertiesAsJson(_pointer)).toDartString());

  /// Deletes this document from the database.
  ///
  /// Deletions are replicated.
  Future<void> delete([
    ConcurrencyControl concurrency = ConcurrencyControl.failOnConflict,
  ]) {
    _debugDocumentHasBeenSaved();
    return _worker!.execute(DeleteDocument(_pointer.address, concurrency));
  }

  /// Purges this document.
  ///
  /// This removes all traces of the document from the database. Purges are not
  /// replicated. If the document is changed on a server, it will be re-created
  /// when pulled.
  Future<void> purge() {
    _debugDocumentHasBeenSaved();
    return _worker!.execute(PurgeDocument(_pointer.address));
  }

  /// {@macro cbl.document.mutableCopy}
  MutableDocument mutableCopy() => MutableDocument.mutableCopy(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Document &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sequence == other.sequence &&
          properties == other.properties;

  @override
  int get hashCode => id.hashCode ^ sequence.hashCode ^ properties.hashCode;

  @override
  String toString() => 'Document('
      'id: $id, '
      'sequence: $sequence'
      ')';

  void _debugDocumentHasBeenSaved() {
    assert(_worker != null, 'Document has not been saved');
  }
}

/// A [Document] whose [properties] can be changed.
///
/// A mutable document exposes its properties as a mutable dictionary, so you
/// can change them in place and then call [Database.saveDocument] to persist
/// the changes.
class MutableDocument extends Document {
  static late final _bindings = CBLBindings.instance.mutableDocument;

  MutableDocument._(
    Pointer<Void> pointer,
    Worker? worker,
    bool? retain,
    this.isNew,
  ) : super._(pointer, worker, retain);

  /// Creates a new, empty document in memory.
  ///
  /// It will not be added to a database until saved.
  factory MutableDocument([String? id]) {
    final pointer = runArena(() =>
        _bindings.makeNew(id == null ? nullptr : id.toNativeUtf8().asScoped));
    return createMutableDocument(pointer: pointer, isNew: true);
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
        pointer: _bindings.mutableCopy(original._pointer),
        worker: original._worker,
      );

  /// A new document has not been saved to the [Database] while an old document
  /// has been pulled ouf the Database.
  final bool isNew;

  /// The properties as a mutable dictionary.
  ///
  /// Other than the [Dict] returned by [Document.properties], this value's
  /// lifetime is not tied to this document.
  @override
  MutableDict get properties =>
      MutableDict.fromPointer(_bindings.mutableProperties(_pointer));

  set properties(MutableDict properties) {
    _bindings.setProperties(_pointer, properties.ref);
  }

  set propertiesAsJson(String json) {
    runArena(() {
      _bindings
          .setPropertiesAsJSON(
              _pointer, json.toNativeUtf8().asScoped, globalError)
          .checkResultAndError();
    });
  }

  @override
  String toString() => 'MutableDocument('
      'id: $id, '
      'sequence: $sequence'
      ')';
}
