import 'ffi.dart';

/// Setting this flag to `true` enables printing of debug information for ref
/// counted native CBL objects in debug builds.
bool get debugRefCounted => _debugRefCountedObject;
bool _debugRefCountedObject = false;

// ignore: avoid_positional_boolean_parameters
set debugRefCounted(bool value) {
  if (_debugRefCountedObject != value) {
    _debugRefCountedObject = value;
    cblBindings.base.debugRefCounted = value;
  }
}
