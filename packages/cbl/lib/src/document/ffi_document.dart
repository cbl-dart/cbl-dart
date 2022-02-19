import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../fleece/containers.dart' as fl;
import '../fleece/encoder.dart';
import '../fleece/integration/integration.dart';
import '../support/encoding.dart';
import '../support/ffi.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import 'document.dart';

late final _documentBindings = cblBindings.document;
late final _mutableDocumentBindings = cblBindings.mutableDocument;

class FfiDocumentDelegate extends DocumentDelegate
    implements NativeResource<CBLDocument> {
  FfiDocumentDelegate.fromPointer({
    required Pointer<CBLDocument> doc,
    bool adopt = true,
    required String debugCreator,
  }) : native = CBLObject(
          doc,
          adopt: adopt,
          debugName: 'FfiDocumentDelegate(creator: $debugCreator)',
        );

  FfiDocumentDelegate.create([String? id])
      : this.fromPointer(
          doc: _mutableDocumentBindings.createWithID(id).cast(),
          debugCreator: 'FfiDocumentDelegate.mutable()',
        );

  factory FfiDocumentDelegate.mutableCopy(FfiDocumentDelegate delegate) {
    final delegateNative = delegate.native;
    final result = FfiDocumentDelegate.fromPointer(
      doc: _mutableDocumentBindings.mutableCopy(delegateNative.pointer).cast(),
      debugCreator: 'FfiDocumentDelegate.mutableCopy()',
    );
    cblReachabilityFence(delegateNative);
    return result;
  }

  @override
  NativeObject<CBLDocument> native;

  @override
  String get id {
    final result = _documentBindings.id(native.pointer);
    cblReachabilityFence(native);
    return result;
  }

  @override
  String? get revisionId {
    final result = _documentBindings.revisionId(native.pointer);
    cblReachabilityFence(native);
    return result;
  }

  @override
  int get sequence {
    final result = _documentBindings.sequence(native.pointer);
    cblReachabilityFence(native);
    return result;
  }

  @override
  EncodedData? get properties => _properties ??= _readEncodedProperties();
  EncodedData? _properties;

  @override
  set properties(EncodedData? value) {
    _writeEncodedProperties(value!);
    _properties = value;
  }

  Pointer<FLValue> get _nativeProperties =>
      _documentBindings.properties(native.pointer).cast();

  set _nativeProperties(Pointer<FLValue> value) => _mutableDocumentBindings
      .setProperties(native.pointer.cast(), value.cast());

  @override
  MRoot createMRoot(MContext context, {required bool isMutable}) {
    final result = MRoot.fromValue(
      _nativeProperties,
      context: context,
      isMutable: isMutable,
    );
    cblReachabilityFence(native);
    return result;
  }

  EncodedData _readEncodedProperties() {
    final encoder = FleeceEncoder()..writeValue(_nativeProperties);
    cblReachabilityFence(native);
    return EncodedData.fleece(encoder.finish());
  }

  void _writeEncodedProperties(EncodedData value) {
    final doc = fl.Doc.fromResultData(value.toFleece(), FLTrust.trusted);
    final dict = fl.MutableDict.mutableCopy(doc.root.asDict!);
    _nativeProperties = dict.pointer;
    cblReachabilityFence(native);
    cblReachabilityFence(dict);
  }

  @override
  DocumentDelegate toMutable() => FfiDocumentDelegate.mutableCopy(this);
}
