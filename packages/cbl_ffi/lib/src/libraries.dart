import 'dart:ffi';
import 'dart:io';

class LibraryConfiguration {
  LibraryConfiguration({this.process, this.name, this.appendExtension})
      : assert((process != null && name == null && appendExtension == null) ||
            name != null);

  final bool? process;
  final String? name;
  final bool? appendExtension;

  DynamicLibrary get library {
    if (name != null) {
      final name =
          this.name! + (appendExtension == true ? dynamicLibraryExtension : '');
      return DynamicLibrary.open(name);
    }
    if (process == true) return DynamicLibrary.process();
    return DynamicLibrary.executable();
  }

  static late final String dynamicLibraryExtension = (() {
    if (Platform.isAndroid || Platform.isLinux || Platform.isFuchsia) {
      return '.so';
    }
    if (Platform.isIOS || Platform.isMacOS) return '.dylib';
    if (Platform.isWindows) return '.dll';
    throw UnimplementedError('Support for platform is not implemented');
  })();
}

class Libraries {
  Libraries({
    this.enterpriseEdition = false,
    required LibraryConfiguration cbl,
    required LibraryConfiguration cblDart,
  })  : _cbl = cbl,
        _cblDart = cblDart;

  final LibraryConfiguration _cbl;
  final LibraryConfiguration _cblDart;

  final bool enterpriseEdition;

  DynamicLibrary get cbl => _cbl.library;

  DynamicLibrary? get cblEE => enterpriseEdition ? cbl : null;

  DynamicLibrary get cblDart => _cblDart.library;
}
