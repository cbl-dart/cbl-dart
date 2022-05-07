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
    _code.writeln('AsyncDatabase.openInternal(name, config, _adapter);');
    _code.writeln();

    _code.writeln('static SyncDatabase openSync(');
    _code.writeln('String name, [');
    _code.writeln('DatabaseConfiguration? config,');
    _code.writeln(']) =>');
    _code.writeln('    // ignore: invalid_use_of_internal_member');
    _code.writeln('SyncDatabase.internal(name, config, _adapter);');
    _code.writeln();

    _code.writeln('static final _adapter = TypedDataRegistry(');

    _code.writeln('types: [');

    model.types.forEach(_writeTypedDataMetadata);

    _code.writeln('],');

    _code.writeln(');');

    _code.writeln('}');

    return _code.toString();
  }

  void _writeTypedDataMetadata(TypedDataObjectModel object) {
    switch (object.kind) {
      case TypedDataObjectKind.dictionary:
        _code.write('TypedDictionaryMetadata');
        break;
      case TypedDataObjectKind.document:
        _code.write('TypedDocumentMetadata');
        break;
    }

    _code
      ..writeln(
        '<${object.classNames.declaringClassName},'
        ' ${object.classNames.mutableClassName}>(',
      )
      ..writeln("dartName: '${object.classNames.declaringClassName}',")
      ..writeln('factory: ${object.classNames.immutableClassName}.internal,')
      ..writeln(
        'mutableFactory: ${object.classNames.mutableClassName}.internal,',
      );

    final typeMatcher = object.typeMatcher;
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
