import 'dart:ffi';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../fleece/fleece.dart' as fl;
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

  FfiDocumentDelegate.mutableCopy(FfiDocumentDelegate delegate)
      : this.fromPointer(
          doc:
              delegate.native.call(_mutableDocumentBindings.mutableCopy).cast(),
          debugCreator: 'FfiDocumentDelegate.mutableCopy()',
        );

  @override
  NativeObject<CBLDocument> native;

  @override
  String get id => native.call(_documentBindings.id);

  @override
  String? get revisionId => native.call(_documentBindings.revisionId);

  @override
  int get sequence => native.call(_documentBindings.sequence);

  EncodedData? _properties;

  @override
  EncodedData get properties => _properties ??= _readProperties();

  @override
  set properties(EncodedData value) {
    _writePropertiesDict(value);
    _properties = value;
  }

  @override
  MRoot createMRoot(MContext context, {required bool isMutable}) =>
      runNativeCalls(() => MRoot.fromValue(
            _readPropertiesDict().pointer,
            context: context,
            isMutable: isMutable,
          ));

  EncodedData _readProperties() => EncodedData.fleece(
        runNativeCalls(() => (fl.FleeceEncoder()
              ..writeValue(_readPropertiesDict().pointer))
            .finish()),
      );

  fl.Dict _readPropertiesDict() =>
      fl.Dict.fromPointer(native.call(_documentBindings.properties));

  void _writePropertiesDict(EncodedData value) {
    final doc = fl.Doc.fromResultData(value.toFleece(), FLTrust.trusted);
    final dict = fl.MutableDict.mutableCopy(doc.root.asDict!);

    runNativeCalls(() => _mutableDocumentBindings.setProperties(
          native.pointer.cast(),
          dict.native.pointer.cast(),
        ));
  }

  @override
  DocumentDelegate toMutable() => FfiDocumentDelegate.mutableCopy(this);
}
