import 'dart:ffi';

import '../bindings.dart';
import '../fleece/containers.dart';
import 'base.dart';
import 'cblite.dart';
import 'cblitedart.dart' hide CBLCert, CBLCollection;
import 'global.dart';
import 'utils.dart';

final class UrlEndpointListenerBindings extends Bindings {
  UrlEndpointListenerBindings(super.libraries);

  late final _authenticatorFinalizer =
      NativeFinalizer(cbl.addresses.CBLListenerAuth_Free.cast());

  void bindAuthenticatorToDartObject(
    Finalizable object,
    Pointer<CBLListenerAuthenticator> pointer,
  ) {
    _authenticatorFinalizer.attach(object, pointer.cast());
  }

  Pointer<CBLListenerAuthenticator> createPasswordAuthenticator(
          CBLDartListenerPasswordAuthCallback handler) =>
      cbl.CBLListenerAuth_CreatePassword(
        cblDart.addresses.CBLDart_ListenerPasswordAuthCallbackTrampoline,
        handler.cast(),
      );

  Pointer<CBLListenerAuthenticator> createCertificateAuthenticator(
          CBLDartListenerCertAuthCallback handler) =>
      cbl.CBLListenerAuth_CreateCertificate(
        cblDart.addresses.CBLDart_ListenerCertAuthCallbackTrampoline,
        handler.cast(),
      );

  Pointer<CBLListenerAuthenticator> createCertificateAuthenticatorWithRoots(
    Pointer<CBLCert> roots,
  ) =>
      cbl.CBLListenerAuth_CreateCertificateWithRootCerts(roots);

  int? port(Pointer<CBLURLEndpointListener> pointer) {
    final port = cbl.CBLURLEndpointListener_Port(pointer);
    return port == 0 ? null : port;
  }

  Pointer<CBLURLEndpointListener> create({
    required List<Pointer<CBLCollection>> collections,
    int? port,
    String? networkInterface,
    required bool disableTls,
    Pointer<CBLTLSIdentity>? tlsIdentity,
    Pointer<CBLListenerAuthenticator>? authenticator,
    required bool enableDeltaSync,
    required bool readOnly,
  }) =>
      withGlobalArena(() {
        final config = globalArena<CBLURLEndpointListenerConfiguration>();

        final collectionsArray =
            globalArena<Pointer<CBLCollection>>(collections.length);
        for (var i = 0; i < collections.length; i++) {
          collectionsArray[i] = collections[i];
        }

        config.ref.collections = collectionsArray;
        config.ref.collectionCount = collections.length;
        config.ref.port = port ?? 0;
        config.ref.networkInterface = networkInterface.toFLString();
        config.ref.disableTLS = disableTls;
        config.ref.tlsIdentity = tlsIdentity ?? nullptr;
        config.ref.authenticator = authenticator ?? nullptr;
        config.ref.enableDeltaSync = enableDeltaSync;
        config.ref.readOnly = readOnly;

        return cbl.CBLURLEndpointListener_Create(config, globalCBLError)
            .checkError();
      });

  List<Uri>? urls(Pointer<CBLURLEndpointListener> pointer) =>
      cbl.CBLURLEndpointListener_Urls(pointer)
          .toNullable()
          ?.let((pointer) => MutableArray.fromPointer(pointer, adopt: true))
          .let((array) =>
              array.map((value) => Uri.parse(value.asString!)).toList());

  CBLConnectionStatus connectionStatus(
    Pointer<CBLURLEndpointListener> pointer,
  ) =>
      cbl.CBLURLEndpointListener_Status(pointer);

  void start(Pointer<CBLURLEndpointListener> pointer) =>
      cbl.CBLURLEndpointListener_Start(pointer, globalCBLError).checkError();

  void stop(Pointer<CBLURLEndpointListener> pointer) =>
      cbl.CBLURLEndpointListener_Stop(pointer);
}
