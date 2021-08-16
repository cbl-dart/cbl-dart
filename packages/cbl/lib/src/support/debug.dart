import 'ffi.dart';
import 'native_object.dart';

/// Setting this flag to `true` enables printing of debug information for
/// [CblObject] in debug builds.
bool get debugRefCounted => _debugRefCountedObject;
bool _debugRefCountedObject = false;

// ignore: avoid_positional_boolean_parameters
set debugRefCounted(bool value) {
  if (_debugRefCountedObject != value) {
    _debugRefCountedObject = value;
    cblBindings.base.debugRefCounted = value;
  }
}
