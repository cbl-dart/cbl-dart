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
    _code.writeln('''
mixin ${_classNames.interfaceMixinName} implements
    Typed${_internalType}Object<${_classNames.mutableClassName}> {

''');

    // Fields are either declared as constructor parameter or as abstract
    // getters. So, we only need to write the getters in the interface mixin
    // for fields that are constructor parameters.
    object.fields
        .where((field) => field.constructorParameter != null)
        .forEach(_writeAbstractPropertyGetter);

    _code.writeln('}');
  }

  void _writeImplBase() {
    _code.writeln('''
abstract class ${_classNames.implBaseName}<I extends $_internalType>
    with ${_classNames.interfaceMixinName}
    implements ${_classNames.declaringClassName} {

  ${_classNames.implBaseName}(this.internal);

  @override
  final I internal;

''');

    _writeDocumentMetadataGetters();

    // Property getters for un-cached properties
    object.properties
        .where((property) => !property.type.isCached)
        .forEach(_writeUncachedPropertyGetter);

    _writeToMutableMethod();

    _writeToStringMethod();

    _code.writeln('}');
  }

  void _writeImmutableClass() {
    _code.writeln('''
/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ${_classNames.immutableClassName} extends ${_classNames.implBaseName} {

  ${_classNames.immutableClassName}.internal(super.internal);

''');

    object.properties.where((property) => property.type.isCached).toList()
      ..forEach(_writePropertyConverterField)
      ..forEach(_writeImmutableCachedPropertyField);

    _writeEqualsAndHashCode();

    _code.writeln('}');
  }

  void _writeMutableClass() {
    _code.writeln('''
/// Mutable version of [${_classNames.declaringClassName}].
class ${_classNames.mutableClassName}
    extends ${_classNames.implBaseName}<$_mutableInternalType>
    implements TypedMutable${_internalType}Object<${_classNames.declaringClassName}, ${_classNames.mutableClassName}> {

  /// Creates a new mutable [${_classNames.declaringClassName}].
  ${_classNames.mutableClassName}(
''');

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
        ..write(field.name);

      if (field is TypedDataObjectProperty) {
        final defaultValueCode = field.defaultValueCode;
        if (defaultValueCode != null) {
          _code
            ..write(' = ')
            ..write(defaultValueCode);
        }
      }

      _code.write(',');
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
          ..write(documentIdField.name)
          ..write(' == null ? ')
          ..write(_mutableInternalType)
          ..write('() : ');
      }
      _code
        ..write(_mutableInternalType)
        ..write('.withId(')
        ..write(documentIdField.name)
        ..write(')');
    } else {
      _code
        ..write(_mutableInternalType)
        ..write('()');
    }

    _code.write(')');

    // Property initializers
    if (object.properties.isEmpty) {
      _code
        ..writeln(';')
        ..writeln();
    } else {
      _code.writeln(' {');
      for (final field in object.properties) {
        if (field.isNullable) {
          _code
            ..write('if (')
            ..write(field.name)
            ..writeln(' != null) {');
        }
        _code
          ..write('    this.')
          ..write(field.name)
          ..write(' =')
          ..write(field.name)
          ..writeln(';');
        if (field.isNullable) {
          _code.writeln('}');
        }
      }
      _code
        ..writeln('  }')
        ..writeln();
    }

    // Internal constructor
    _code.writeln('''
${_classNames.mutableClassName}.internal(super.internal);

''');

    object.properties
        .where((property) => property.type.isCached)
        .forEach(_writeMutablePropertyConverterField);

    for (final property in object.properties) {
      final type = property.type;
      if (type.isCached) {
        _writeMutableCachedPropertyField(property);
        _writeMutableCachedPropertyGetter(property);
      }

      _writePropertySetter(property);
    }

    _code.writeln('}');
  }

  void _writeAbstractPropertyGetter(TypedDataObjectField field) {
    final documentationComment =
        field.constructorParameter?.documentationComment;
    if (documentationComment != null) {
      _code.writeln(documentationComment);
    }
    _code.writeln('''
${field.type.dartTypeWithNullability} get ${field.name};

    ''');
  }

  void _writePropertyConverterField(TypedDataObjectProperty property) {
    _code.writeln('''
static const ${property.converterField} = ${_buildTypeConverterExpression(property.type, forMutable: false)};

''');
  }

  void _writeMutablePropertyConverterField(TypedDataObjectProperty property) {
    _code.writeln('''
static const ${property.converterField} = ${_buildTypeConverterExpression(property.type, forMutable: true)};

''');
  }

  void _writeDocumentMetadataGetters() {
    final idFieldName = object.documentIdField?.name;
    if (idFieldName != null) {
      _code.writeln('''
@override
String get $idFieldName => internal.id;

    ''');
    }

    final sequenceFieldName = object.documentSequenceField?.name;
    if (sequenceFieldName != null) {
      _code.writeln('''
@override
int get $sequenceFieldName => internal.sequence;

    ''');
    }

    final revisionIdFieldName = object.documentRevisionIdField?.name;
    if (revisionIdFieldName != null) {
      _code.writeln('''
@override
String? get $revisionIdFieldName => internal.revisionId;

    ''');
    }
  }

  void _writeUncachedPropertyGetter(TypedDataObjectProperty property) {
    final type = property.type;

    _code.writeln('''
@override
${type.dartTypeWithNullability} get ${property.name} => ${property.readHelper}(
      internal: internal,
      name: ${escapeDartString(property.name)},
      key: ${escapeDartString(property.property)},
      converter: ${_buildTypeConverterExpression(type, forMutable: false)},
    );

    ''');
  }

  void _writeToMutableMethod() {
    _code.writeln('''
@override
${_classNames.mutableClassName} toMutable() =>
    ${_classNames.mutableClassName}.internal(internal.toMutable());
    ''');
  }

  void _writeToStringMethod() {
    final metadataOrder = [
      DocumentMetadataKind.id,
      DocumentMetadataKind.sequence,
      DocumentMetadataKind.revisionId,
    ];
    final propertyOrder = metadataOrder.length;
    int fieldOrder(TypedDataObjectField field) {
      if (field is TypedDataMetadataField) {
        return metadataOrder.indexOf(field.kind);
      } else {
        return propertyOrder;
      }
    }

    final sortedFields = object.fields.toList()
      ..sort((a, b) => fieldOrder(a) - fieldOrder(b));

    final fields = [
      for (final field in sortedFields)
        '${escapeDartString(field.name)}: ${field.name},',
    ].join('\n');

    _code.writeln('''
@override
String toString({String? indent}) => TypedDataHelpers.renderString(
      indent: indent,
      className: ${escapeDartString(_classNames.declaringClassName)},
      fields: {
        $fields
      },
    );

''');
  }

  void _writeEqualsAndHashCode() {
    _code.writeln('''
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is ${_classNames.declaringClassName} &&
        runtimeType == other.runtimeType &&
        internal == other.internal;

@override
int get hashCode => internal.hashCode;

''');
  }

  void _writeImmutableCachedPropertyField(TypedDataObjectProperty property) {
    _code.writeln('''
@override
late final ${property.name} = ${property.readHelper}(
    internal: internal,
    name: ${escapeDartString(property.name)},
    key: ${escapeDartString(property.property)},
    converter: ${property.converterField},
  );

    ''');
  }

  void _writeMutableCachedPropertyField(TypedDataObjectProperty property) {
    final type = property.type;
    _code.writeln('''
late ${type.mutableDartTypeWithNullability} ${property.cacheField} = ${property.readHelper}(
      internal: internal,
      name: ${escapeDartString(property.name)},
      key: ${escapeDartString(property.property)},
      converter: ${property.converterField},
    );

    ''');
  }

  void _writeMutableCachedPropertyGetter(TypedDataObjectProperty property) {
    _code.writeln('''
@override
${property.type.mutableDartTypeWithNullability} get ${property.name} =>
    ${property.cacheField};

    ''');
  }

  void _writePropertySetter(TypedDataObjectProperty property) {
    final type = property.type;
    final converter = property.type.isCached
        ? property.converterField
        : _buildTypeConverterExpression(type, forMutable: true);
    _code.writeln([
      '''
set ${property.name}(${type.dartTypeWithNullability} value) {
  final promoted = ${property.isNullable ? 'value == null ? null : ' : ''}$converter.promote(value);''',
      if (property.type.isCached)
        '''
  ${property.cacheField} = promoted;''',
      '''
  ${property.writeHelper}(
    internal: internal,
    key: ${escapeDartString(property.property)},
    value: promoted,
    converter: $converter,
  );
}

    '''
    ].join('\n'));
  }

  String _buildTypeConverterExpression(
    TypedDataType type, {
    required bool forMutable,
  }) {
    if (type is BuiltinScalarType) {
      return 'TypedDataHelpers.${type.dartType.decapitalized}Converter';
    } else if (type is CustomScalarType) {
      return 'const ScalarConverterAdapter(${type.converter.code},)';
    } else if (type is TypedDataObjectType) {
      final classNames = type.classNames;
      final internalClass = forMutable ? 'MutableDictionary' : 'Dictionary';
      final factoryClass = forMutable
          ? classNames.mutableClassName
          : classNames.immutableClassName;
      final targetClass = forMutable
          ? classNames.mutableClassName
          : classNames.declaringClassName;
      final promotableClass = forMutable
          ? classNames.declaringClassName
          : 'TypedDictionaryObject<$targetClass>';

      return 'const TypedDictionaryConverter<'
          '$internalClass, $targetClass, $promotableClass'
          '>($factoryClass.internal)';
    } else if (type is TypedDataListType) {
      return '''
const TypedListConverter(
  converter: ${_buildTypeConverterExpression(type.elementType, forMutable: forMutable)},
  isNullable: ${type.elementType.isNullable},
  isCached: ${type.elementType.isCached},
)
''';
    } else {
      throw UnimplementedError();
    }
  }
}

extension on TypedDataObjectProperty {
  String get readHelper => isNullable
      ? 'TypedDataHelpers.readNullableProperty'
      : 'TypedDataHelpers.readProperty';

  String get writeHelper => isNullable
      ? 'TypedDataHelpers.writeNullableProperty'
      : 'TypedDataHelpers.writeProperty';

  String get converterField => '_${name}Converter';

  String get cacheField => '_$name';
}
