import 'package:cbl_ffi/cbl_ffi.dart';

late final cblBindings = () {
  final bindings = CBLBindings.maybeInstance;
  if (bindings == null) {
    throw StateError(
      'CouchbaseLite.init must be called before using the cbl library.',
    );
  }
  return bindings;
}();
