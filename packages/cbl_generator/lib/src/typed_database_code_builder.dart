// ignore_for_file: cascade_invocations

import 'package:cbl/cbl.dart';
import 'package:source_helper/source_helper.dart';

import 'model.dart';

class TypeDataBaseCodeBuilder {
  TypeDataBaseCodeBuilder(this.model);

  final TypedDatabaseModel model;

  final _code = StringBuffer();

  String build() {
    _code.writeln(
        'class ${model.className} extends ${model.declaringClassName} {');

    _code.writeln('static Future<AsyncDatabase> openAsync(');
    _code.writeln('String name, [');
    _code.writeln('DatabaseConfiguration? config,');
    _code.writeln(']) =>');
    _code.writeln('    // ignore: invalid_use_of_internal_member');
    _code.writeln('AsyncDatabase.openInternal(name, config, _registry);');
    _code.writeln();

    _code.writeln('static SyncDatabase openSync(');
    _code.writeln('String name, [');
    _code.writeln('DatabaseConfiguration? config,');
    _code.writeln(']) =>');
    _code.writeln('    // ignore: invalid_use_of_internal_member');
    _code.writeln('SyncDatabase.internal(name, config, _registry);');
    _code.writeln();

    _code.writeln('static final _registry = TypedDataRegistry(');

    _code.writeln('types: [');

    model.types.forEach(_writeTypedDataMetadata);

    _code.writeln('],');

    _code.writeln(');');

    _code.writeln('}');

    return _code.toString();
  }

  void _writeTypedDataMetadata(TypedDataClassModel type) {
    switch (type.type) {
      case TypedDataType.dictionary:
        _code.write('TypedDictionaryMetadata');
        break;
      case TypedDataType.document:
        _code.write('TypedDocumentMetadata');
        break;
    }

    _code
      ..writeln(
        '<${type.classNames.declaringClassName},'
        ' ${type.classNames.mutableClassName}>(',
      )
      ..writeln("dartName: '${type.classNames.declaringClassName}',")
      ..writeln('factory: ${type.classNames.immutableClassName}.internal,')
      ..writeln(
        'mutableFactory: ${type.classNames.mutableClassName}.internal,',
      );

    final typeMatcher = type.typeMatcher;
    if (typeMatcher is ValueTypeMatcher) {
      final pathLiteral = typeMatcher.path.map((segment) {
        if (segment is String) {
          return escapeDartString(segment);
        } else {
          return segment;
        }
      }).join(', ');
      _code
        ..writeln('typeMatcher: const ValueTypeMatcher(')
        ..writeln('path: [$pathLiteral],');
      if (typeMatcher.value != null) {
        _code.writeln('value: ${escapeDartString(typeMatcher.value!)},');
      }
      _code.writeln('),');
    }

    _code.writeln('),');
  }
}
