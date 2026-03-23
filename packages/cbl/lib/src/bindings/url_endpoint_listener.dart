import 'dart:ffi';

import '../fleece/containers.dart';
import '../support/isolate.dart';
import 'base.dart';
import 'cblite.dart' as cblite;
import 'cblitedart.dart' as cblitedart;
import 'global.dart';
import 'utils.dart';

final class UrlEndpointListenerBindings {
  static final _authenticatorFinalizer = NativeFinalizer(
    cblite.addresses.CBLListenerAuth_Free.cast(),
  );

  static void bindAuthenticatorToDartObject(
    Finalizable object,
    Pointer<cblite.CBLListenerAuthenticator> pointer,
  ) {
    _authenticatorFinalizer.attach(object, pointer.cast());
  }

  static Pointer<cblite.CBLListenerAuthenticator> createPasswordAuthenticator(
    cblitedart.CBLDartListenerPasswordAuthCallback handler,
  ) {
    ensureInitializedForCurrentIsolate();
    return cblite.CBLListenerAuth_CreatePassword(
      cblitedart.addresses.CBLDart_ListenerPasswordAuthCallbackTrampoline,
      handler.cast(),
    );
  }

  static Pointer<cblite.CBLListenerAuthenticator>
  createCertificateAuthenticator(
    cblitedart.CBLDartListenerCertAuthCallback handler,
  ) {
    ensureInitializedForCurrentIsolate();
    return cblite.CBLListenerAuth_CreateCertificate(
      cblitedart.addresses.CBLDart_ListenerCertAuthCallbackTrampoline,
      handler.cast(),
    );
  }

  static Pointer<cblite.CBLListenerAuthenticator>
  createCertificateAuthenticatorWithRoots(Pointer<cblite.CBLCert> roots) {
    ensureInitializedForCurrentIsolate();
    return cblite.CBLListenerAuth_CreateCertificateWithRootCerts(roots);
  }

  static Pointer<cblite.CBLURLEndpointListener> create({
    required List<Pointer<cblite.CBLCollection>> collections,
    int? port,
    String? networkInterface,
    required bool disableTls,
    Pointer<cblite.CBLTLSIdentity>? tlsIdentity,
    Pointer<cblite.CBLListenerAuthenticator>? authenticator,
    required bool enableDeltaSync,
    required bool readOnly,
  }) {
    ensureInitializedForCurrentIsolate();
    return withGlobalArena(() {
      final config = globalArena<cblite.CBLURLEndpointListenerConfiguration>();

      final collectionsArray = globalArena<Pointer<cblite.CBLCollection>>(
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
  }

  static int? port(Pointer<cblite.CBLURLEndpointListener> pointer) {
    ensureInitializedForCurrentIsolate();
    final port = cblite.CBLURLEndpointListener_Port(pointer);
    return port == 0 ? null : port;
  }

  static List<Uri>? urls(Pointer<cblite.CBLURLEndpointListener> pointer) {
    ensureInitializedForCurrentIsolate();
    return cblite.CBLURLEndpointListener_Urls(pointer)
        .toNullable()
        ?.let((pointer) => MutableArray.fromPointer(pointer, adopt: true))
        .let(
          (array) => array.map((value) => Uri.parse(value.asString!)).toList(),
        );
  }

  static Pointer<cblite.CBLTLSIdentity>? tlsIdentity(
    Pointer<cblite.CBLURLEndpointListener> pointer,
  ) {
    ensureInitializedForCurrentIsolate();
    return cblite.CBLURLEndpointListener_TLSIdentity(pointer).toNullable();
  }

  static cblite.CBLConnectionStatus connectionStatus(
    Pointer<cblite.CBLURLEndpointListener> pointer,
  ) {
    ensureInitializedForCurrentIsolate();
    return cblite.CBLURLEndpointListener_Status(pointer);
  }

  static void start(Pointer<cblite.CBLURLEndpointListener> pointer) {
    ensureInitializedForCurrentIsolate();
    cblite.CBLURLEndpointListener_Start(pointer, globalCBLError).checkError();
  }

  static void stop(Pointer<cblite.CBLURLEndpointListener> pointer) {
    ensureInitializedForCurrentIsolate();
    cblite.CBLURLEndpointListener_Stop(pointer);
  }
}
