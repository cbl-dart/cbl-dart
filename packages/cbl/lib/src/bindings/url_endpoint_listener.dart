import 'dart:ffi';

import '../bindings.dart';
import '../fleece/containers.dart';
import 'base.dart';
import 'cblite.dart' as cblite_lib;
import 'cblitedart.dart' as cblitedart_lib;
import 'global.dart';
import 'utils.dart';

final class UrlEndpointListenerBindings extends Bindings {
  UrlEndpointListenerBindings(super.libraries);

  late final _authenticatorFinalizer = NativeFinalizer(
    cblite.addresses.CBLListenerAuth_Free.cast(),
  );

  void bindAuthenticatorToDartObject(
    Finalizable object,
    Pointer<cblite_lib.CBLListenerAuthenticator> pointer,
  ) {
    _authenticatorFinalizer.attach(object, pointer.cast());
  }

  Pointer<cblite_lib.CBLListenerAuthenticator> createPasswordAuthenticator(
    cblitedart_lib.CBLDartListenerPasswordAuthCallback handler,
  ) => cblite.CBLListenerAuth_CreatePassword(
    cblitedart.addresses.CBLDart_ListenerPasswordAuthCallbackTrampoline,
    handler.cast(),
  );

  Pointer<cblite_lib.CBLListenerAuthenticator> createCertificateAuthenticator(
    cblitedart_lib.CBLDartListenerCertAuthCallback handler,
  ) => cblite.CBLListenerAuth_CreateCertificate(
    cblitedart.addresses.CBLDart_ListenerCertAuthCallbackTrampoline,
    handler.cast(),
  );

  Pointer<cblite_lib.CBLListenerAuthenticator>
  createCertificateAuthenticatorWithRoots(Pointer<cblite_lib.CBLCert> roots) =>
      cblite.CBLListenerAuth_CreateCertificateWithRootCerts(roots);

  int? port(Pointer<cblite_lib.CBLURLEndpointListener> pointer) {
    final port = cblite.CBLURLEndpointListener_Port(pointer);
    return port == 0 ? null : port;
  }

  Pointer<cblite_lib.CBLURLEndpointListener> create({
    required List<Pointer<CBLCollection>> collections,
    int? port,
    String? networkInterface,
    required bool disableTls,
    Pointer<cblite_lib.CBLTLSIdentity>? tlsIdentity,
    Pointer<cblite_lib.CBLListenerAuthenticator>? authenticator,
    required bool enableDeltaSync,
    required bool readOnly,
  }) => withGlobalArena(() {
    final config =
        globalArena<cblite_lib.CBLURLEndpointListenerConfiguration>();

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

  List<Uri>? urls(Pointer<cblite_lib.CBLURLEndpointListener> pointer) =>
      cblite.CBLURLEndpointListener_Urls(pointer)
          .toNullable()
          ?.let((pointer) => MutableArray.fromPointer(pointer, adopt: true))
          .let(
            (array) =>
                array.map((value) => Uri.parse(value.asString!)).toList(),
          );

  cblite_lib.CBLConnectionStatus connectionStatus(
    Pointer<cblite_lib.CBLURLEndpointListener> pointer,
  ) => cblite.CBLURLEndpointListener_Status(pointer);

  void start(Pointer<cblite_lib.CBLURLEndpointListener> pointer) =>
      cblite.CBLURLEndpointListener_Start(pointer, globalCBLError).checkError();

  void stop(Pointer<cblite_lib.CBLURLEndpointListener> pointer) =>
      cblite.CBLURLEndpointListener_Stop(pointer);
}
