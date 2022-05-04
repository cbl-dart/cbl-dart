import 'package:source_helper/source_helper.dart';

import 'model.dart';
import 'utils.dart';

class TypeDataCodeBuilder {
  TypeDataCodeBuilder({
    required this.object,
  }) {
    switch (object.kind) {
      case TypedDataObjectKind.document:
        _internalType = 'Document';
        break;
      case TypedDataObjectKind.dictionary:
        _internalType = 'Dictionary';
        break;
    }
  }

  final TypedDataObjectModel object;

  late final String _internalType;
  late final String _mutableInternalType = 'Mutable$_internalType';

  final _code = StringBuffer();

  TypedDataObjectClassNames get _classNames => object.classNames;

  String build() {
    _code.clear();
    _writeInterfaceMixin();
    _writeImplBase();
    _writeImmutableClass();
    _writeMutableClass();
    return _code.toString();
  }

  void _writeInterfaceMixin() {
    _code
      ..write('mixin ')
      ..write(_classNames.interfaceMixinName)
      ..write(' implements Typed${_internalType}Object<')
      ..write(_classNames.mutableClassName)
      ..writeln('> {');

    for (final field in object.fields) {
      if (field.constructorParameter == null) {
        // Fields are either declared as constructor parameter or as abstract
        // getters. So, we only need to write the getters in the interface mixin
        // for fields that are constructor parameters.
        continue;
      }

      _code
        ..write('  ')
        ..write(field.type.dartTypeWithNullability)
        ..write(' get ')
        ..write(field.nameInDart)
        ..writeln(';')
        ..writeln();
    }

    _code.writeln('}');
  }

  void _writeImplBase() {
    _code
      ..write('abstract class ')
      ..write(_classNames.implBaseName)
      ..write('<I extends $_internalType>')
      ..writeln('  with ${_classNames.interfaceMixinName}')
      ..writeln('  implements ${_classNames.declaringClassName} {')
      ..writeln('  ${_classNames.implBaseName}(this.internal);')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  final I internal;')
      ..writeln();

    // Document metadata fields
    final idFieldName = object.documentIdField?.nameInDart;
    if (idFieldName != null) {
      _code
        ..writeln('  @override')
        ..write('String get ')
        ..write(idFieldName)
        ..writeln(' => internal.id;')
        ..writeln();
    }

    final sequenceFieldName = object.documentSequenceField?.nameInDart;
    if (sequenceFieldName != null) {
      _code
        ..writeln('  @override')
        ..write('int get ')
        ..write(sequenceFieldName)
        ..writeln(' => internal.sequence;')
        ..writeln();
    }

    final revisionIdFieldName = object.documentRevisionIdField?.nameInDart;
    if (revisionIdFieldName != null) {
      _code
        ..writeln('  @override')
        ..write('String? get ')
        ..write(revisionIdFieldName)
        ..writeln(' => internal.revisionId;')
        ..writeln();
    }

    // Property getters for un-cached properties
    for (final property in object.properties) {
      final type = property.type;
      if (type.isCached) {
        // Getters of properties of these types are implemented differently for
        // immutable and mutable objects.
        continue;
      }

      final helper = property.isNullable
          ? 'InternalTypedDataHelpers.readNullableProperty'
          : 'InternalTypedDataHelpers.readProperty';

      _code.writeln('''
@override
${type.dartTypeWithNullability} get ${property.nameInDart} => $helper(
    internal: internal,
    name: ${escapeDartString(property.nameInDart)},
    key: ${escapeDartString(property.nameInData)},
    reviver: ${_buildTypeConverterExpression(type)},
  );
''');
    }

    // `toMutable` method
    _code
      ..writeln('  @override')
      ..writeln('  ${_classNames.mutableClassName} toMutable() => '
          '${_classNames.mutableClassName}.internal(internal.toMutable());')
      ..writeln('}');
  }

  void _writeImmutableClass() {
    _code
      ..write('class ')
      ..write(_classNames.immutableClassName)
      ..writeln(' extends ${_classNames.implBaseName} {')
      ..write('  ')
      ..write(_classNames.immutableClassName)
      ..writeln('.internal($_internalType internal): super(internal);')
      ..writeln();

    // Property getters for cached properties
    for (final property in object.properties) {
      final type = property.type;
      if (!type.isCached) {
        continue;
      }

      final helper = property.isNullable
          ? 'InternalTypedDataHelpers.readNullableProperty'
          : 'InternalTypedDataHelpers.readProperty';

      _code.writeln('''
@override
late final ${property.nameInDart} = $helper(
  internal: internal,
  name: ${escapeDartString(property.nameInDart)},
  key: ${escapeDartString(property.nameInData)},
  reviver: ${_buildTypeConverterExpression(type)},
);
''');
    }

    _code.writeln('}');
  }

  void _writeMutableClass() {
    _code
      ..write('class ')
      ..write(_classNames.mutableClassName)
      ..write(' extends ')
      ..write(_classNames.implBaseName)
      ..write('<$_mutableInternalType>')
      ..write(' implements TypedMutable${_internalType}Object<')
      ..write(_classNames.declaringClassName)
      ..write(', ')
      ..write(_classNames.mutableClassName)
      ..writeln('> {')
      ..write('  ${_classNames.mutableClassName}(');

    var isInOptionalPositionList = false;
    var isInNamedList = false;

    for (final field in object.fields) {
      final parameter = field.constructorParameter;
      if (parameter == null) {
        continue;
      }
      if (parameter.isPositional &&
          !parameter.isRequired &&
          !isInOptionalPositionList) {
        assert(!isInNamedList);
        isInOptionalPositionList = true;
        _code.write('[');
      }

      if (!parameter.isPositional && !isInNamedList) {
        assert(!isInOptionalPositionList);
        isInNamedList = true;
        _code.write('{');
      }

      if (!parameter.isPositional && parameter.isRequired) {
        _code.write('required ');
      }

      _code
        ..write(parameter.type.dartTypeWithNullability)
        ..write(' ')
        ..write(field.nameInDart)
        ..write(',');
    }

    if (isInOptionalPositionList) {
      _code.write(']');
    }
    if (isInNamedList) {
      _code.write('}');
    }

    _code.write('): super(');

    final documentIdField = object.documentIdField;
    if (documentIdField != null &&
        documentIdField.constructorParameter != null) {
      if (documentIdField.constructorParameter!.type.isNullable) {
        _code
          ..write(documentIdField.nameInDart)
          ..write(' == null ? ')
          ..write(_mutableInternalType)
          ..write('() : ');
      }
      _code
        ..write(_mutableInternalType)
        ..write('.withId(')
        ..write(documentIdField.nameInDart)
        ..write(')');
    } else {
      _code
        ..write(_mutableInternalType)
        ..write('()');
    }

    _code.write(')');

    // Property initializers
    if (object.properties.isEmpty) {
      _code.writeln(';');
    } else {
      _code.writeln(' {');
      for (final field in object.properties) {
        if (field.isNullable) {
          _code
            ..write('if (')
            ..write(field.nameInDart)
            ..writeln(' != null) {');
        }
        _code
          ..write('    this.')
          ..write(field.nameInDart)
          ..write(' =')
          ..write(field.nameInDart)
          ..writeln(';');
        if (field.isNullable) {
          _code.writeln('}');
        }
      }
      _code.writeln('  }');
    }

    // Internal constructor
    _code
      ..writeln()
      ..write('  ')
      ..write(_classNames.mutableClassName)
      ..writeln('.internal($_mutableInternalType internal): super(internal);')
      ..writeln();

    for (final property in object.properties) {
      final type = property.type;
      if (type.isCached) {
        // Property getter for cached properties
        final readHelper = property.isNullable
            ? 'InternalTypedDataHelpers.readNullableProperty'
            : 'InternalTypedDataHelpers.readProperty';

        final storageFieldName = '_${property.nameInDart}';

        _code.writeln('''
late ${type.dartTypeWithNullability} $storageFieldName = $readHelper(
  internal: internal,
  name: ${escapeDartString(property.nameInDart)},
  key: ${escapeDartString(property.nameInData)},
  reviver: ${_buildTypeConverterExpression(type)},
);

@override
${type.dartTypeWithNullability} get ${property.nameInDart} => $storageFieldName;
''');

        if (type is TypedDataObjectType) {
          // Property setter for type data object
          final writeHelper = property.isNullable
              ? 'InternalTypedDataHelpers.writeNullableProperty'
              : 'InternalTypedDataHelpers.writeProperty';

          if (type.isNullable) {
            _code.writeln('''
set ${property.nameInDart}(${type.classNames.declaringClassName}? value) {
  if (value != null && value is! ${type.classNames.mutableClassName}) {
    value = value.toMutable();
  }
  $storageFieldName = value;
  $writeHelper(
    internal: internal,
    key: ${escapeDartString(property.nameInData)},
    value: value,
    freezer: ${_buildTypeConverterExpression(type)},
  );
}
''');
          } else {
            _code.writeln('''
set ${property.nameInDart}(${type.classNames.declaringClassName} value) {
  if (value is! ${type.classNames.mutableClassName}) {
    value = value.toMutable();
  }
  $storageFieldName = value;
  $writeHelper(
    internal: internal,
    key: ${escapeDartString(property.nameInData)},
    value: value,
    freezer: ${_buildTypeConverterExpression(type)},
  );
}
''');
          }
        } else if (type is TypedDataListType) {
          // Property setter for type data lists
          final writeHelper = property.isNullable
              ? 'InternalTypedDataHelpers.writeNullableProperty'
              : 'InternalTypedDataHelpers.writeProperty';

          if (type.isNullable) {
            _code.writeln('''
set ${property.nameInDart}(${type.dartType}? value) {
  if (value != null && (value is! TypedDataList<${type.elementType.dartType}> || value.internal is! MutableArray)) {
    value = ${_buildTypeConverterExpression(type)}.revive(MutableArray())..addAll(value);
  }
  $storageFieldName = value;
  $writeHelper(
    internal: internal,
    key: ${escapeDartString(property.nameInData)},
    value: value,
    freezer: ${_buildTypeConverterExpression(type)},
  );
}
''');
          } else {
            _code.writeln('''
set ${property.nameInDart}(${type.dartType} value) {
  if (value is! TypedDataList<${type.elementType.dartType}> || value.internal is! MutableArray) {
    value = ${_buildTypeConverterExpression(type)}.revive(MutableArray())..addAll(value);
  }
  $storageFieldName = value;
  $writeHelper(
    internal: internal,
    key: ${escapeDartString(property.nameInData)},
    value: value,
    freezer: ${_buildTypeConverterExpression(type)},
  );
}
''');
          }
        }
      } else {
        // Property setters for un-cached
        final helper = property.isNullable
            ? 'InternalTypedDataHelpers.writeNullableProperty'
            : 'InternalTypedDataHelpers.writeProperty';

        _code.writeln('''
set ${property.nameInDart}(${type.dartTypeWithNullability} value) => $helper(
  internal: internal,
  key: ${escapeDartString(property.nameInData)},
  value: value,
  freezer: ${_buildTypeConverterExpression(type)},
);
''');
      }
    }

    _code.writeln('}');
  }

  String _buildTypeConverterExpression(TypedDataType type) {
    if (type is BuiltinScalarType) {
      return 'InternalTypedDataHelpers.${type.dartType.decapitalized}Converter';
    } else if (type is TypedDataObjectType) {
      final factory = '${type.classNames.mutableClassName}.internal';
      return 'const TypedDictionaryConverter($factory)';
    } else if (type is TypedDataListType) {
      return '''
const TypedListConverter(
  converter: ${_buildTypeConverterExpression(type.elementType)},
  isNullable: ${type.elementType.isNullable},
  isCached: ${type.elementType.isCached},
)
''';
    } else {
      throw UnimplementedError();
    }
  }
}
