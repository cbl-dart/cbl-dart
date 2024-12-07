import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:yaml/yaml.dart';

class FfigenConfig {
  FfigenConfig({
    required this.name,
    this.output,
    this.import,
  });

  static Future<FfigenConfig> fromYaml(YamlMap yaml) async {
    final name = yaml['name'] as String;

    FfigenOutput? output;
    if (yaml['output'] case final value?) {
      output = await FfigenOutput.fromYaml(value as YamlMap);
    }

    FfigenImport? import;
    if (yaml['import'] case final value?) {
      import = await FfigenImport.fromYaml(value as YamlMap);
    }

    return FfigenConfig(
      name: name,
      output: output,
      import: import,
    );
  }

  static Future<FfigenConfig> load(String path) async {
    final file = File(path);
    final fileContents = await file.readAsString();
    final yaml = loadYaml(fileContents, sourceUrl: file.uri);
    return FfigenConfig.fromYaml(yaml as YamlMap);
  }

  final String name;
  final FfigenOutput? output;
  final FfigenImport? import;
}

class FfigenOutput {
  FfigenOutput({
    required this.bindings,
    required this.symbolFile,
  });

  static Future<FfigenOutput> fromYaml(YamlMap yaml) async {
    String? bindings;
    if (yaml['bindings'] case final value?) {
      bindings = await yaml.resolvePath(value as String);
    }

    FfigenSymbolFile? symbolFile;
    if (yaml['symbol-file'] case final value?) {
      symbolFile = await FfigenSymbolFile.fromYaml(value as YamlMap);
    }

    return FfigenOutput(
      bindings: bindings,
      symbolFile: symbolFile,
    );
  }

  final String? bindings;
  final FfigenSymbolFile? symbolFile;
}

class FfigenSymbolFile {
  FfigenSymbolFile({
    required this.output,
    required this.importPath,
  });

  static Future<FfigenSymbolFile> fromYaml(YamlMap yaml) async {
    String? output;
    if (yaml['output'] case final value?) {
      output = await yaml.resolvePath(value as String);
    }

    final importPath = yaml['import-path'] as String?;

    return FfigenSymbolFile(
      output: output,
      importPath: importPath,
    );
  }

  final String? output;
  final String? importPath;
}

class FfigenImport {
  FfigenImport({required this.symbolFiles});

  static Future<FfigenImport> fromYaml(YamlMap yaml) async {
    List<String>? symbolFiles;
    if (yaml['symbol-files'] case final value?) {
      symbolFiles = [];
      for (final item in value as YamlList) {
        symbolFiles.add(await yaml.resolvePath(item as String));
      }
    }

    return FfigenImport(
      symbolFiles: symbolFiles,
    );
  }

  final List<String>? symbolFiles;
}

extension on YamlNode {
  Future<String> resolvePath(String value) async =>
      (await _resolveUri(Uri.parse(value), span.sourceUrl!)).path;
}

Future<Uri> _resolveUri(Uri uri, Uri sourceUrl) async {
  if (uri.scheme == 'package') {
    return (await findPackageConfigUri(sourceUrl))!.resolve(uri)!;
  } else {
    return sourceUrl.resolveUri(uri);
  }
}
