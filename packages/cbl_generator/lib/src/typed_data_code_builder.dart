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

    // Document metadata fields
    _writeDocumentMetadataGetters();

    // Property getters for un-cached properties
    object.properties
        .where((property) => !property.type.isCached)
        .forEach(_writePrimitiveScalarGetter);

    // `toMutable` method
    _writeToMutableMethod();
  }

  void _writeImmutableClass() {
    _code.writeln('''
class ${_classNames.immutableClassName} extends ${_classNames.implBaseName} {

  ${_classNames.immutableClassName}.internal($_internalType internal): super(internal);

''');

    // Property getters for cached properties
    object.properties
        .where((property) => property.type.isCached)
        .forEach(_writeImmutableCachedPropertyField);

    _code.writeln('}');
  }

  void _writeMutableClass() {
    _code.writeln('''
class ${_classNames.mutableClassName}
    extends ${_classNames.implBaseName}<$_mutableInternalType>
    implements TypedMutable${_internalType}Object<${_classNames.declaringClassName}, ${_classNames.mutableClassName}> {

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
      _code
        ..writeln(';')
        ..writeln();
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
      _code
        ..writeln('  }')
        ..writeln();
    }

    // Internal constructor
    _code.writeln('''
${_classNames.mutableClassName}.internal($_mutableInternalType internal): super(internal);

''');

    for (final property in object.properties) {
      final type = property.type;
      if (type.isCached) {
        _writeMutableCachedPropertyField(property);
        _writeMutableCachedPropertyGetter(property);
      }

      if (type is BuiltinScalarType) {
        _writeBuiltinScalarSetter(property);
      } else if (type is TypedDataObjectType) {
        _writeTypeDataObjectSetter(property);
      } else if (type is TypedDataListType) {
        _writeTypedDataListSetter(property);
      }
    }

    _code.writeln('}');
  }

  void _writeAbstractPropertyGetter(TypedDataObjectField field) {
    _code.writeln('''
${field.type.dartTypeWithNullability} get ${field.nameInDart};

    ''');
  }

  void _writeDocumentMetadataGetters() {
    final idFieldName = object.documentIdField?.nameInDart;
    if (idFieldName != null) {
      _code.writeln('''
@override
String get $idFieldName => internal.id;

    ''');
    }

    final sequenceFieldName = object.documentSequenceField?.nameInDart;
    if (sequenceFieldName != null) {
      _code.writeln('''
@override
int get $sequenceFieldName => internal.sequence;

    ''');
    }

    final revisionIdFieldName = object.documentRevisionIdField?.nameInDart;
    if (revisionIdFieldName != null) {
      _code.writeln('''
@override
String? get $revisionIdFieldName => internal.revisionId;

    ''');
    }
  }

  void _writePrimitiveScalarGetter(TypedDataObjectProperty property) {
    final type = property.type;

    _code.writeln('''
@override
${type.dartTypeWithNullability} get ${property.nameInDart} => ${property.readHelper}(
      internal: internal,
      name: ${escapeDartString(property.nameInDart)},
      key: ${escapeDartString(property.nameInData)},
      reviver: ${_buildTypeConverterExpression(type)},
    );

    ''');
  }

  void _writeToMutableMethod() {
    _code.writeln('''
@override
${_classNames.mutableClassName} toMutable() =>
    ${_classNames.mutableClassName}.internal(internal.toMutable());
    }
    ''');
  }

  void _writeImmutableCachedPropertyField(TypedDataObjectProperty property) {
    _code.writeln('''
@override
late final ${property.nameInDart} = ${property.readHelper}(
    internal: internal,
    name: ${escapeDartString(property.nameInDart)},
    key: ${escapeDartString(property.nameInData)},
    reviver: ${_buildTypeConverterExpression(property.type)},
  );

    ''');
  }

  void _writeMutableCachedPropertyField(TypedDataObjectProperty property) {
    final type = property.type;
    _code.writeln('''
late ${type.dartTypeWithNullability} ${property.privateCacheField} = ${property.readHelper}(
      internal: internal,
      name: ${escapeDartString(property.nameInDart)},
      key: ${escapeDartString(property.nameInData)},
      reviver: ${_buildTypeConverterExpression(type)},
    );

    ''');
  }

  void _writeMutableCachedPropertyGetter(TypedDataObjectProperty property) {
    _code.writeln('''
@override
${property.type.dartTypeWithNullability} get ${property.nameInDart} =>
    ${property.privateCacheField};

    ''');
  }

  void _writeBuiltinScalarSetter(TypedDataObjectProperty property) {
    final type = property.type;
    _code.writeln('''
set ${property.nameInDart}(${type.dartTypeWithNullability} value) => ${property.writeHelper}(
      internal: internal,
      key: ${escapeDartString(property.nameInData)},
      value: value,
      freezer: ${_buildTypeConverterExpression(type)},
    );

    ''');
  }

  void _writeTypeDataObjectSetter(TypedDataObjectProperty property) {
    final type = property.type as TypedDataObjectType;

    var mutableValueCheck = 'value is! ${type.classNames.mutableClassName}';
    if (type.isNullable) {
      mutableValueCheck = 'value != null && $mutableValueCheck';
    }

    _code.writeln('''
set ${property.nameInDart}(${type.classNames.declaringClassName}${type.isNullable ? '?' : ''} value) {
  if ($mutableValueCheck) {
    value = value.toMutable();
  }
  ${property.privateCacheField} = value;
  ${property.writeHelper}(
    internal: internal,
    key: ${escapeDartString(property.nameInData)},
    value: value,
    freezer: ${_buildTypeConverterExpression(type)},
  );
}

    ''');
  }

  void _writeTypedDataListSetter(TypedDataObjectProperty property) {
    final type = property.type as TypedDataListType;

    var mutableValueCheck =
        'value is! TypedDataList<${type.elementType.dartType}> || '
        'value.internal is! MutableArray';
    if (type.isNullable) {
      mutableValueCheck = 'value != null && ($mutableValueCheck)';
    }

    _code.writeln('''
set ${property.nameInDart}(${type.dartTypeWithNullability} value) {
  if ($mutableValueCheck) {
    value = ${_buildTypeConverterExpression(type)}.revive(MutableArray())..addAll(value);
  }
  ${property.privateCacheField} = value;
  ${property.writeHelper}(
    internal: internal,
    key: ${escapeDartString(property.nameInData)},
    value: value,
    freezer: ${_buildTypeConverterExpression(type)},
  );
}

    ''');
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

extension on TypedDataObjectProperty {
  String get readHelper => isNullable
      ? 'InternalTypedDataHelpers.readNullableProperty'
      : 'InternalTypedDataHelpers.readProperty';

  String get writeHelper => isNullable
      ? 'InternalTypedDataHelpers.writeNullableProperty'
      : 'InternalTypedDataHelpers.writeProperty';

  String get privateCacheField => '_$nameInDart';
}
