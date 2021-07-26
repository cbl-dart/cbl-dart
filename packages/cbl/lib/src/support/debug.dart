import 'package:cbl_ffi/cbl_ffi.dart';

import 'native_object.dart';

/// Setting this flag to `true` enables printing of debug information for
/// [CblObject] in debug builds.
bool get debugRefCounted => _debugRefCountedObject;
bool _debugRefCountedObject = false;

set debugRefCounted(bool value) {
  if (_debugRefCountedObject != value) {
    _debugRefCountedObject = value;
    CBLBindings.instance.base.debugRefCounted = value;
  }
}
