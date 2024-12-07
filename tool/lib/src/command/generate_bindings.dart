// ignore_for_file: cascade_invocations

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;

import '../ffigen_config.dart';
import '../utils.dart';
import 'base_command.dart';

const _symbolAddressesClassName = 'SymbolAddresses';
const _nativeAssetLibraryAlias = 'native';

final class GenerateBindings extends BaseCommand {
  @override
  String get name => 'generate-bindings';

  @override
  String get description => 'Regenerates FFI bindings.';

  @override
  Future<void> doRun() async {
    final cbliteGenerator = _BindingsGenerator(
      packageDir: projectLayout.packages.cbl.rootDir,
      ffigenConfig: 'cblite_ffigen.yaml',
      logger: logger,
      findAndReplaceInBindings: {
        '_$_symbolAddressesClassName': _symbolAddressesClassName,
      },
    );
    final cblitedartGenerator = _BindingsGenerator(
      packageDir: projectLayout.packages.cbl.rootDir,
      ffigenConfig: 'cblitedart_ffigen.yaml',
      logger: logger,
      findAndReplaceInBindings: {
        '_$_symbolAddressesClassName': _symbolAddressesClassName,
        '''
void CBLDart_CBLLog_SetCallbackLevel(
    imp1.CBLLogLevel level,
  )''': '''
void CBLDart_CBLLog_SetCallbackLevel(
    int level,
  )''',
        '''
typedef DartCBLDart_CBLLog_SetCallbackLevel = void Function(
    imp1.CBLLogLevel level);''': '''
typedef DartCBLDart_CBLLog_SetCallbackLevel = void Function(int level);''',
        '''
  external imp1.CBLQueryLanguage expressionLanguage;''': '''
  @imp1.CBLQueryLanguage()
  external int expressionLanguage;''',
        '''
  external imp1.CBLReplicatorType replicatorType;''': '''
  @imp1.CBLReplicatorType()
  external int replicatorType;''',
      },
    );
    final cbliteNativeAssetsGenerator = _BindingsGenerator(
      packageDir: projectLayout.packages.cblNativeAssets.rootDir,
      ffigenConfig: 'cblite_native_assets_ffigen.yaml',
      logger: logger,
      legacyBindings: cbliteGenerator,
    );
    final cblitedartNativeAssetsGenerator = _BindingsGenerator(
      packageDir: projectLayout.packages.cblNativeAssets.rootDir,
      ffigenConfig: 'cblitedart_native_assets_ffigen.yaml',
      logger: logger,
      legacyBindings: cblitedartGenerator,
    );

    final generators = [
      cbliteGenerator,
      cblitedartGenerator,
      cbliteNativeAssetsGenerator,
      cblitedartNativeAssetsGenerator,
    ];

    for (final generator in generators) {
      await generator.generate();
    }
  }
}

class _BindingsGenerator {
  _BindingsGenerator({
    required this.packageDir,
    required this.ffigenConfig,
    required this.logger,
    this.findAndReplaceInBindings = const {},
    this.legacyBindings,
  });

  final String packageDir;
  final String ffigenConfig;
  final Logger logger;
  final Map<String, String> findAndReplaceInBindings;
  final _BindingsGenerator? legacyBindings;

  Future<void> generate() async {
    await _generateSymbolsFile();
    await _runFfigen();
    await _findAndReplaceInBindings();
    await _fixNativeBindings();
    await _generateNativeBindingsImplementation();
  }

  Future<FfigenConfig> _loadFfigenConfig() =>
      FfigenConfig.load(p.join(packageDir, ffigenConfig));

  Future<void> _generateSymbolsFile() async {
    final legacyBindings = this.legacyBindings;
    if (legacyBindings == null) {
      return;
    }

    await logger.runWithProgress(
      message: 'Generating symbol file for $ffigenConfig',
      showTiming: true,
      () async {
        final legacyFfigenConfig = await legacyBindings._loadFfigenConfig();

        // Extract the method names of the legacy bindings.
        final legacyBindingsFile = File(legacyFfigenConfig.output!.bindings!);
        final legacyBindingsContents = await legacyBindingsFile.readAsString();
        final parsedResult = parseString(
          content: legacyBindingsContents,
          path: legacyBindingsFile.path,
        );
        final visitor = _MethodNamesCollector()
          ..visitCompilationUnit(parsedResult.unit);
        final bindingsMethodNames =
            visitor.methodsByClass[legacyFfigenConfig.name]!;

        // Read the symbol file from the legacy bindings.
        final legacySymbolFile =
            File(legacyFfigenConfig.output!.symbolFile!.output!);
        var legacySymbolFileLines = await legacySymbolFile.readAsLines();

        // Remove the method names of the legacy bindings from the symbol file
        // so that they are generated again in the new bindings.
        legacySymbolFileLines = legacySymbolFileLines
            .whereNot((line) => bindingsMethodNames
                .any((methodName) => line.contains(methodName)))
            .toList();

        // Write the new symbol file.
        final ffigenConfig = await _loadFfigenConfig();
        final symbolFile = File(ffigenConfig.import!.symbolFiles!.last);
        await symbolFile.writeAsString(legacySymbolFileLines.join('\n'));
      },
    );
  }

  Future<void> _runFfigen() async {
    await logger.runWithProgress(
      message: 'Running ffigen for $ffigenConfig',
      showTiming: true,
      () async {
        await runProcess(
          'dart',
          [
            'run',
            'ffigen',
            '--config',
            ffigenConfig,
          ],
          workingDirectory: packageDir,
          logger: logger,
        );
      },
    );
  }

  Future<void> _findAndReplaceInBindings() async {
    if (findAndReplaceInBindings.isEmpty) {
      return;
    }

    await logger.runWithProgress(
      message: 'Find-and-replacing in bindings from $ffigenConfig',
      showTiming: true,
      () async {
        final ffigenConfig = await _loadFfigenConfig();
        final bindingsFile = File(ffigenConfig.output!.bindings!);
        var bindingsContents = await bindingsFile.readAsString();

        for (final MapEntry(key: find, value: replace)
            in findAndReplaceInBindings.entries) {
          logger.trace('Find:\n$find\n\nReplace:\n$replace\n');
          bindingsContents = bindingsContents.replaceAll(find, replace);
        }

        await bindingsFile.writeAsString(bindingsContents);
      },
    );
  }

  Future<void> _fixNativeBindings() async {
    if (legacyBindings == null) {
      return;
    }

    await logger.runWithProgress(
      message: 'Fixing native bindings from $ffigenConfig',
      showTiming: true,
      () async {
        const symbols = [
          'CBLConcurrencyControl',
          'CBLDart_IsolateId',
          'CBLDistanceMetric',
          'CBLLogDomain',
          'CBLLogLevel',
          'CBLMaintenanceType',
          'CBLQueryLanguage',
          'CBLReplicatorType',
          'CBLScalarQuantizerType',
          'CBLSeekBase',
          'CBLTimestamp',
          'Dart_Port',
          'FLTimestamp',
        ];

        final ffigenConfig = await _loadFfigenConfig();
        final bindingsFile = File(ffigenConfig.output!.bindings!);
        final bindingsLines = await bindingsFile.readAsLines();
        final newBindingsLines = <String>[];

        final bindingsLinesIterator = bindingsLines.iterator;
        var inExternalBlock = false;
        while (bindingsLinesIterator.moveNext()) {
          var line = bindingsLinesIterator.current;
          if (line.startsWith('external')) {
            inExternalBlock = true;
          }

          if (inExternalBlock) {
            for (final symbol in symbols) {
              line = line.replaceAll('imp1.$symbol', 'imp1.Dart$symbol');
              line = line.replaceAll('imp2.$symbol', 'imp2.Dart$symbol');
            }
          }

          if (line.endsWith(';')) {
            inExternalBlock = false;
          }

          newBindingsLines.add(line);
        }

        await bindingsFile.writeAsString(newBindingsLines.join('\n'));
      },
    );
  }

  Future<void> _generateNativeBindingsImplementation() async {
    final legacyBindings = this.legacyBindings;
    if (legacyBindings == null) {
      return;
    }

    await logger.runWithProgress(
      message: 'Generating native bindings implementation for $ffigenConfig',
      showTiming: true,
      () async {
        final legacyFfigenConfig = await legacyBindings._loadFfigenConfig();
        final ffigenConfig = await _loadFfigenConfig();

        final legacyBindingsFile = File(legacyFfigenConfig.output!.bindings!);
        final legacyBindingsContents = await legacyBindingsFile.readAsString();
        final legacyBindingsParseResult = parseString(
          content: legacyBindingsContents,
          path: legacyBindingsFile.path,
        );

        final bindingsGenerator = _NativeBindingsGenerator(
          bindingsClassName: legacyFfigenConfig.name,
          legacyBindingsLibraryPath:
              legacyFfigenConfig.output!.symbolFile!.importPath!,
        );

        final nativeBindingsFile = File(p.join(
          packageDir,
          'lib',
          'src',
          '${ffigenConfig.name}_native_bindings.dart',
        ));

        await nativeBindingsFile.writeAsString(
          bindingsGenerator.generate(legacyBindingsParseResult.unit),
        );
      },
    );
  }
}

/// Collects the method names of all classes in the AST.
class _MethodNamesCollector extends RecursiveAstVisitor {
  final Map<String, List<String>> methodsByClass = {};

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final clazz = node.parent! as ClassDeclaration;
    methodsByClass
        .putIfAbsent(clazz.name.lexeme, () => [])
        .add(node.name.lexeme);
  }
}

/// Generates an implementation of a ffigen generated bindings class which uses
/// the corresponding `@Native` bindings.
class _NativeBindingsGenerator extends RecursiveAstVisitor {
  _NativeBindingsGenerator({
    required this.bindingsClassName,
    required this.legacyBindingsLibraryPath,
  });

  final String bindingsClassName;
  final String legacyBindingsLibraryPath;

  String generate(CompilationUnit unit) {
    _buffer.clear();
    visitCompilationUnit(unit);
    return DartFormatter().format(_buffer.toString());
  }

  final StringBuffer _buffer = StringBuffer();

  late String _nativeBindingsPrefix;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _buffer
      ..writeln('// AUTO GENERATED FILE, DO NOT EDIT.')
      ..writeln('//')
      ..writeln('// ignore_for_file: type=lint, unused_import')
      ..writeln("import 'dart:ffi' as ffi;")
      ..writeln()
      ..writeln("import '$legacyBindingsLibraryPath';")
      ..writeln("import 'package:cbl/src/bindings/cblite.dart' as imp1;")
      ..writeln(
          "import './$bindingsClassName.dart' as $_nativeAssetLibraryAlias;")
      ..writeln();

    super.visitCompilationUnit(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final className = node.name.lexeme;
    final nativeClassName = '${className}Native';

    if (className != bindingsClassName &&
        className != _symbolAddressesClassName) {
      return;
    }

    if (className == bindingsClassName) {
      _nativeBindingsPrefix = _nativeAssetLibraryAlias;
    }
    if (className == _symbolAddressesClassName) {
      _nativeBindingsPrefix = '$_nativeAssetLibraryAlias.addresses';
    }

    _buffer.writeln('class $nativeClassName implements $className {');
    _buffer.writeln();

    _buffer.writeln('  const $nativeClassName();');
    _buffer.writeln();

    if (className == bindingsClassName) {
      _buffer.writeln('@override');
      _buffer.writeln(
        'final addresses = const ${_symbolAddressesClassName}Native();',
      );
      _buffer.writeln();
    }

    super.visitClassDeclaration(node);

    _buffer.writeln('}');
    _buffer.writeln();
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final methodName = node.name.lexeme;
    final nativeMethodName = '$_nativeBindingsPrefix.$methodName';

    _buffer.writeln('@override');
    _buffer.write(node.returnType?.toSource() ?? 'void');
    _buffer.write(' ');
    if (node.isGetter) {
      _buffer.write('get ');
    }
    if (node.isSetter) {
      _buffer.write('set ');
    }
    _buffer.write(methodName);

    if (node.isGetter) {
      _buffer.write(' => $nativeMethodName;');
    } else {
      _buffer.write('(');
      if (node.parameters?.parameters case final parameters?) {
        for (final parameter in parameters) {
          final parameterName = parameter.name!.lexeme;

          switch (parameter) {
            case FieldFormalParameter(:final type) ||
                  SimpleFormalParameter(:final type):
              _buffer.write(type!.toSource());
              _buffer.write(' ');
              _buffer.write(parameterName);
              _buffer.write(', ');
            default:
              throw UnsupportedError('Unsupported parameter type: $parameter');
          }
        }
      }

      if (node.isSetter) {
        _buffer.write(') => $nativeMethodName = value;');
      } else {
        _buffer.writeln(') =>');
        _buffer.writeln('    $nativeMethodName(');
        if (node.parameters?.parameters case final parameters?) {
          for (final parameter in parameters) {
            final parameterName = parameter.name!.lexeme;
            _buffer.write(parameterName);
            _buffer.write(', ');
          }
        }
        _buffer.write(');');
      }
    }
    _buffer.writeln();
    _buffer.writeln();
  }
}
