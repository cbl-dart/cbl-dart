import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import 'database.dart';
import 'fleece.dart';
import 'native_object.dart';
import 'resource.dart';
import 'worker/cbl_worker.dart';

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

  /// Returns this documents id.
  String get id => _bindings.id(native.pointerUnsafe);

  /// The revision id, which is a short opaque string that's
  /// guaranteed to be unique to every change made to the document.
  ///
  /// If the document doesn't exist yet, it is `null`.
  String? get revisionId => _bindings.revisionId(native.pointerUnsafe);

  /// Returns the current sequence in the local database.
  ///
  /// This number increases every time the document is saved, and a more
  /// recently saved document will have a greater sequence number than one saved
  /// earlier, so sequences may be used as an abstract 'clock' to tell relative
  /// modification times.
  int get sequence => _bindings.sequence(native.pointerUnsafe);

  /// The properties as a dictionary.
  Dict get properties => Dict.fromPointer(
        _bindings.properties(native.pointerUnsafe),
        retain: true,
        release: true,
      );

  /// The properties as a JSON string.
  String get propertiesAsJson => _bindings.createJSON(native.pointerUnsafe);

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
  factory MutableDocument([String? id]) => createMutableDocument(
        pointer: _bindings.createWithID(id),
        worker: null,
        retain: false,
        isNew: true,
      );

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
    _bindings.setJSON(_mutablePointer, json);
  }

  @override
  String toString() => 'MutableDocument('
      'id: $id, '
      'revisionId: $revisionId, '
      'sequence: $sequence'
      ')';
}
