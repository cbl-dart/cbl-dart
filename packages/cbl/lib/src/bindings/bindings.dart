import 'libraries.dart';
import 'tracing.dart';

abstract base class Bindings {
  Bindings(Bindings parent) : libs = parent.libs {
    parent._children.add(this);
  }

  Bindings.root(this.libs);

  final DynamicLibraries libs;

  List<Bindings> get _children => [];
}

final class CBLBindings extends Bindings {
  CBLBindings(LibrariesConfiguration config)
      : super.root(DynamicLibraries.fromConfig(config));

  static CBLBindings? _instance;

  static CBLBindings get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError('CBLBindings have not been initialized.');
    }

    return instance;
  }

  static CBLBindings? get maybeInstance => _instance;

  static void init(
    LibrariesConfiguration libraries, {
    TracedCallHandler? onTracedCall,
  }) {
    assert(_instance == null, 'CBLBindings have already been initialized.');

    _instance = CBLBindings(libraries);

    if (onTracedCall != null) {
      _onTracedCall = onTracedCall;
    }
  }
}

set _onTracedCall(TracedCallHandler value) => onTracedCall = value;
