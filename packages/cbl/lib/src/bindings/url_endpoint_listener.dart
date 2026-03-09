import 'dart:ffi';

import '../bindings.dart';
import '../fleece/containers.dart';
import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'global.dart';
import 'utils.dart';

final class UrlEndpointListenerBindings {
  const UrlEndpointListenerBindings();

  static final _authenticatorFinalizer = NativeFinalizer(
    cblite.addresses.CBLListenerAuth_Free.cast(),
  );

  void bindAuthenticatorToDartObject(
    Finalizable object,
    Pointer<cblite.CBLListenerAuthenticator> pointer,
  ) {
    _authenticatorFinalizer.attach(object, pointer.cast());
  }

  Pointer<cblite.CBLListenerAuthenticator> createPasswordAuthenticator(
    cblitedart.CBLDartListenerPasswordAuthCallback handler,
  ) => cblite.CBLListenerAuth_CreatePassword(
    cblitedart.addresses.CBLDart_ListenerPasswordAuthCallbackTrampoline,
    handler.cast(),
  );

  Pointer<cblite.CBLListenerAuthenticator> createCertificateAuthenticator(
    cblitedart.CBLDartListenerCertAuthCallback handler,
  ) => cblite.CBLListenerAuth_CreateCertificate(
    cblitedart.addresses.CBLDart_ListenerCertAuthCallbackTrampoline,
    handler.cast(),
  );

  Pointer<cblite.CBLListenerAuthenticator>
  createCertificateAuthenticatorWithRoots(Pointer<cblite.CBLCert> roots) =>
      cblite.CBLListenerAuth_CreateCertificateWithRootCerts(roots);

  Pointer<cblite.CBLURLEndpointListener> create({
    required List<Pointer<CBLCollection>> collections,
    int? port,
    String? networkInterface,
    required bool disableTls,
    Pointer<cblite.CBLTLSIdentity>? tlsIdentity,
    Pointer<cblite.CBLListenerAuthenticator>? authenticator,
    required bool enableDeltaSync,
    required bool readOnly,
  }) => withGlobalArena(() {
    final config = globalArena<cblite.CBLURLEndpointListenerConfiguration>();

    final collectionsArray = globalArena<Pointer<CBLCollection>>(
      collections.length,
    );
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

    return cblite.CBLURLEndpointListener_Create(
      config,
      globalCBLError,
    ).checkError();
  });

  int? port(Pointer<cblite.CBLURLEndpointListener> pointer) {
    final port = cblite.CBLURLEndpointListener_Port(pointer);
    return port == 0 ? null : port;
  }

  List<Uri>? urls(Pointer<cblite.CBLURLEndpointListener> pointer) =>
      cblite.CBLURLEndpointListener_Urls(pointer)
          .toNullable()
          ?.let((pointer) => MutableArray.fromPointer(pointer, adopt: true))
          .let(
            (array) =>
                array.map((value) => Uri.parse(value.asString!)).toList(),
          );

  Pointer<cblite.CBLTLSIdentity>? tlsIdentity(
    Pointer<cblite.CBLURLEndpointListener> pointer,
  ) => cblite.CBLURLEndpointListener_TLSIdentity(pointer).toNullable();

  cblite.CBLConnectionStatus connectionStatus(
    Pointer<cblite.CBLURLEndpointListener> pointer,
  ) => cblite.CBLURLEndpointListener_Status(pointer);

  void start(Pointer<cblite.CBLURLEndpointListener> pointer) =>
      cblite.CBLURLEndpointListener_Start(pointer, globalCBLError).checkError();

  void stop(Pointer<cblite.CBLURLEndpointListener> pointer) =>
      cblite.CBLURLEndpointListener_Stop(pointer);
}
