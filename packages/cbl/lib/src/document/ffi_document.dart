import 'dart:ffi';
import 'dart:typed_data';

import 'package:cbl_ffi/cbl_ffi.dart';

import '../fleece/fleece.dart' as fl;
import '../fleece/integration/integration.dart';
import '../support/ffi.dart';
import '../support/native_object.dart';
import '../support/resource.dart';
import 'document.dart';

late final _documentBindings = cblBindings.document;
late final _mutableDocumentBindings = cblBindings.mutableDocument;

class FfiDocumentDelegate extends DocumentDelegate
    with NativeResourceMixin<CBLDocument> {
  FfiDocumentDelegate({
    required Pointer<CBLDocument> doc,
    bool adopt = true,
    required String debugCreator,
  }) : native = CblObject(
          doc,
          adopt: adopt,
          debugName: 'FfiDocumentDelegate(creator: $debugCreator)',
        );

  FfiDocumentDelegate.createMutable([String? id])
      : this(
          doc: _mutableDocumentBindings.createWithID(id).cast(),
          debugCreator: 'FfiDocumentDelegate.mutable()',
        );

  @override
  NativeObject<CBLDocument> native;

  @override
  String get id => native.call(_documentBindings.id);

  @override
  String? get revisionId => native.call(_documentBindings.revisionId);

  @override
  int get sequence => native.call(_documentBindings.sequence);

  Uint8List? _properties;

  @override
  Uint8List get properties => _properties ??= _readProperties();

  @override
  set properties(Uint8List value) {
    _writePropertiesDict(value);
    _properties = value;
  }

  @override
  MRoot createMRoot(MContext context, bool isMutable) => runNativeCalls(() {
        return MRoot.fromValue(
          _readPropertiesDict().pointer,
          context: context,
          isMutable: isMutable,
        );
      });

  Uint8List _readProperties() => runNativeCalls(() {
        return (fl.FleeceEncoder()..writeValue(_readPropertiesDict().pointer))
            .finish()
            .asUint8List();
      });

  fl.Dict _readPropertiesDict() =>
      fl.Dict.fromPointer(native.call(_documentBindings.properties));

  void _writePropertiesDict(Uint8List value) {
    final doc = fl.Doc.fromResultData(value, FLTrust.trusted);
    final dict = fl.MutableDict.mutableCopy(doc.root.asDict!);

    runNativeCalls(() => _mutableDocumentBindings.setProperties(
          native.pointer.cast(),
          dict.native.pointer.cast(),
        ));
  }

  @override
  DocumentDelegate toMutable() => FfiDocumentDelegate(
        doc: native.call(_mutableDocumentBindings.mutableCopy).cast(),
        debugCreator: 'FfiDocumentDelegate.toMutable()',
      );

  static void replaceWithMutableCopy({
    required DelegateDocument source,
    required MutableDelegateDocument target,
  }) {
    final sourceDelegate = source.delegate as FfiDocumentDelegate;
    target.setDelegate(sourceDelegate.toMutable());
  }
}

extension FfiMutableDelegateDocumentExt on MutableDelegateDocument {
  FfiDocumentDelegate prepareFfiDelegate() {
    var currentDelegate = delegate;
    if (currentDelegate is FfiDocumentDelegate) {
      flushPropertiesToDelegate();
      return currentDelegate;
    }

    if (currentDelegate is NewDocumentDelegate) {
      flushPropertiesToDelegate();

      final newDelegate = FfiDocumentDelegate.createMutable(delegate.id)
        ..properties = currentDelegate.properties;

      // We just copied the properties so there is no need to update the
      // documents properties.
      setDelegate(newDelegate, updateDocumentProperties: false);

      return newDelegate;
    }

    throw StateError(
      'DocumentDelegate of unexpected type ${delegate.runtimeType}. '
      'This is a bug.',
    );
  }
}
