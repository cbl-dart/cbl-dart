import 'dart:ffi';
import 'dart:io';

bool _isApple = Platform.isIOS || Platform.isMacOS;
bool _isUnix = Platform.isIOS ||
    Platform.isMacOS ||
    Platform.isAndroid ||
    Platform.isLinux ||
    Platform.isFuchsia;

String _buildDynamicLibraryExtension({String? version}) {
  String extension;
  if (_isApple) {
    extension = '.dylib';
  } else if (_isUnix) {
    extension = '.so';
  } else if (Platform.isWindows) {
    extension = '.dll';
  } else {
    throw UnimplementedError();
  }

  if (version != null) {
    if (_isApple) {
      extension = '.$version$extension';
    } else if (_isUnix) {
      extension = '$extension.$version';
    } else {
      throw UnimplementedError();
    }
  }

  return extension;
}

class LibraryConfiguration {
  LibraryConfiguration({
    this.process,
    this.name,
    this.appendExtension,
    this.version,
  }) : assert((process != null && name == null && appendExtension == null) ||
            name != null);

  final bool? process;
  final String? name;
  final bool? appendExtension;
  final String? version;

  DynamicLibrary get library {
    if (name != null) {
      var name = this.name!;
      if (appendExtension == true) {
        name += _buildDynamicLibraryExtension(version: version);
      }
      return DynamicLibrary.open(name);
    }
    if (process == true) {
      return DynamicLibrary.process();
    }
    return DynamicLibrary.executable();
  }
}

class Libraries {
  Libraries({
    required LibraryConfiguration cbl,
    required LibraryConfiguration cblDart,
    this.enterpriseEdition = false,
  })  : _cbl = cbl,
        _cblDart = cblDart;

  final LibraryConfiguration _cbl;
  final LibraryConfiguration _cblDart;

  final bool enterpriseEdition;

  DynamicLibrary get cbl => _cbl.library;

  DynamicLibrary? get cblEE => enterpriseEdition ? cbl : null;

  DynamicLibrary get cblDart => _cblDart.library;
}
