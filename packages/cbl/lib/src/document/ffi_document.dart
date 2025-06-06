import 'dart:ffi';

import '../bindings.dart';
import '../fleece/containers.dart' as fl;
import '../fleece/containers.dart';
import '../fleece/encoder.dart';
import '../fleece/integration/integration.dart';
import '../support/native_object.dart';
import 'document.dart';

final _documentBindings = CBLBindings.instance.document;
final _mutableDocumentBindings = CBLBindings.instance.mutableDocument;

final class FfiDocumentDelegate implements DocumentDelegate, Finalizable {
  FfiDocumentDelegate.fromPointer(this.pointer, {bool adopt = false}) {
    bindCBLRefCountedToDartObject(this, pointer: pointer, adopt: adopt);
  }

  FfiDocumentDelegate.create([String? id])
    : this.fromPointer(
        _mutableDocumentBindings.createWithID(id).cast(),
        adopt: true,
      );

  factory FfiDocumentDelegate.mutableCopy(FfiDocumentDelegate delegate) =>
      FfiDocumentDelegate.fromPointer(
        _mutableDocumentBindings.mutableCopy(delegate.pointer).cast(),
        adopt: true,
      );

  final Pointer<CBLDocument> pointer;

  @override
  String get id => _documentBindings.id(pointer);

  @override
  String? get revisionId => _documentBindings.revisionId(pointer);

  @override
  int get sequence => _documentBindings.sequence(pointer);

  @override
  Data? get encodedProperties =>
      _encodedProperties ??= _readEncodedProperties();
  Data? _encodedProperties;

  fl.Dict get propertiesDict =>
      fl.Dict.fromPointer(_documentBindings.properties(pointer));

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
          data: Value.fromPointer(_documentBindings.properties(pointer).cast()),
        ),
        isMutable: isMutable,
      );

  Data _readEncodedProperties() => FleeceEncoder.fleece.encodeWith((encoder) {
    encoder.writeValue(_documentBindings.properties(pointer).cast());
  });

  void _writeEncodedProperties(Data value) {
    final doc = fl.Doc.fromResultData(value, FLTrust.trusted);
    final dict = fl.MutableDict.mutableCopy(doc.root.asDict!);
    _mutableDocumentBindings.setProperties(pointer.cast(), dict.pointer.cast());
  }

  @override
  DocumentDelegate toMutable() => FfiDocumentDelegate.mutableCopy(this);
}
