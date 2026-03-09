import 'dart:ffi';

import '../bindings.dart';
import '../fleece/containers.dart' as fl;
import '../fleece/containers.dart';
import '../fleece/encoder.dart';
import '../fleece/integration/integration.dart';
import '../support/native_object.dart';
import 'document.dart';

final class FfiDocumentDelegate implements DocumentDelegate, Finalizable {
  FfiDocumentDelegate.fromPointer(this.pointer, {bool adopt = false}) {
    bindCBLRefCountedToDartObject(this, pointer: pointer, adopt: adopt);
  }

  FfiDocumentDelegate.create([String? id])
    : this.fromPointer(
        MutableDocumentBindings.createWithID(id).cast(),
        adopt: true,
      );

  factory FfiDocumentDelegate.mutableCopy(FfiDocumentDelegate delegate) =>
      FfiDocumentDelegate.fromPointer(
        MutableDocumentBindings.mutableCopy(delegate.pointer).cast(),
        adopt: true,
      );

  final Pointer<CBLDocument> pointer;

  @override
  String get id => DocumentBindings.id(pointer);

  @override
  String? get revisionId => DocumentBindings.revisionId(pointer);

  @override
  int get sequence => DocumentBindings.sequence(pointer);

  @override
  Data? get encodedProperties =>
      _encodedProperties ??= _readEncodedProperties();
  Data? _encodedProperties;

  fl.Dict get propertiesDict =>
      fl.Dict.fromPointer(DocumentBindings.properties(pointer));

  @override
  set encodedProperties(Data? value) {
    _writeEncodedProperties(value!);
    _encodedProperties = value;
  }

  @override
  MRoot createMRoot(DelegateDocument document, {required bool isMutable}) =>
      MRoot.fromContext(
        DocumentMContext(
          document,
          data: Value.fromPointer(DocumentBindings.properties(pointer).cast()),
        ),
        isMutable: isMutable,
      );

  Data _readEncodedProperties() => FleeceEncoder.fleece.encodeWith((encoder) {
    encoder.writeValue(DocumentBindings.properties(pointer).cast());
  });

  void _writeEncodedProperties(Data value) {
    final doc = fl.Doc.fromResultData(value, FLTrust.trusted);
    final dict = fl.MutableDict.mutableCopy(doc.root.asDict!);
    MutableDocumentBindings.setProperties(pointer.cast(), dict.pointer.cast());
  }

  @override
  DocumentDelegate toMutable() => FfiDocumentDelegate.mutableCopy(this);
}
