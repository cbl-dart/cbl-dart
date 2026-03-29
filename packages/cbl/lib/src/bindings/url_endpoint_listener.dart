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
      final collectionsArray = globalArena<Pointer<cblite.CBLCollection>>(
        collections.length,
      );
      for (var i = 0; i < collections.length; i++) {
        collectionsArray[i] = collections[i];
      }

      Pointer<Void> niBuf = nullptr;
      var niSize = 0;
      if (networkInterface != null) {
        final (:buf, :size) = encodeStringToArena(
          networkInterface,
          globalArena,
        );
        niBuf = buf;
        niSize = size;
      }

      return cblitedart.CBLDart_CBLURLEndpointListener_Create(
        collectionsArray,
        collections.length,
        port ?? 0,
        niBuf,
        niSize,
        disableTls,
        tlsIdentity ?? nullptr,
        authenticator ?? nullptr,
        enableDeltaSync,
        readOnly,
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
