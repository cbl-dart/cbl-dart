import 'package:collection/collection.dart';
import 'package:source_helper/source_helper.dart';

import 'model.dart';

class TypeDataCodeBuilder {
  TypeDataCodeBuilder({
    required this.clazz,
  }) {
    switch (clazz.type) {
      case TypedDataType.document:
        _internalType = 'Document';
        break;
      case TypedDataType.dictionary:
        _internalType = 'Dictionary';
        break;
    }
  }

  final TypedDataClassModel clazz;

  late final String _internalType;
  late final String _mutableInternalType = 'Mutable$_internalType';

  final _code = StringBuffer();

  TypedDataClassNames get _classNames => clazz.classNames;

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

    for (final field in clazz.fields) {
      if (field.isDocumentId) {
        _code
          ..write('  ')
          ..write(field.type)
          ..write(' get ')
          ..write(field.nameInDart)
          ..writeln(';')
          ..writeln();
      } else {
        _code
          ..write('  ')
          ..write(field.typeWithNullabilitySuffix)
          ..write(' get ')
          ..write(field.nameInDart)
          ..writeln(';')
          ..writeln();
      }
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

    final idFieldName = clazz.idFieldName;
    if (idFieldName != null) {
      _code
        ..writeln('  @override')
        ..write('String get ')
        ..write(idFieldName)
        ..writeln(' => internal.id;')
        ..writeln();
    }

    final sequenceFieldName = clazz.sequenceFieldName;
    if (sequenceFieldName != null) {
      _code
        ..writeln('  @override')
        ..write('int get ')
        ..write(sequenceFieldName)
        ..writeln(' => internal.sequence;')
        ..writeln();
    }

    final revisionIdFieldName = clazz.revisionIdFieldName;
    if (revisionIdFieldName != null) {
      _code
        ..writeln('  @override')
        ..write('String? get ')
        ..write(revisionIdFieldName)
        ..writeln(' => internal.revisionId;')
        ..writeln();
    }

    final properties =
        clazz.fields.where((field) => !field.isDocumentId).toList();
    for (final property in properties) {
      final accessor = property.isNullable
          ? 'InternalTypedDataHelpers.nullableProperty'
          : 'InternalTypedDataHelpers.property';
      _code.writeln('''
@override
${property.typeWithNullabilitySuffix} get ${property.nameInDart} => $accessor(
    internal: internal,
    name: ${escapeDartString(property.nameInDart)},
    key: ${escapeDartString(property.nameInData)},
  );
''');
    }

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
      ..writeln('}');
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

    for (final field in clazz.fields) {
      if (field.isPositional &&
          !field.isRequired &&
          !isInOptionalPositionList) {
        assert(!isInNamedList);
        isInOptionalPositionList = true;
        _code.write('[');
      }

      if (!field.isPositional && !isInNamedList) {
        assert(!isInOptionalPositionList);
        isInNamedList = true;
        _code.write('{');
      }

      if (!field.isPositional && field.isRequired) {
        _code.write('required ');
      }

      _code
        ..write(field.typeWithNullabilitySuffix)
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

    final documentIdField =
        clazz.fields.firstWhereOrNull((element) => element.isDocumentId);

    if (documentIdField != null) {
      if (documentIdField.isNullable) {
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

    final properties =
        clazz.fields.where((element) => !element.isDocumentId).toList();

    // Field initializers
    if (properties.isEmpty) {
      _code.writeln(';');
    } else {
      _code.writeln(' {');
      for (final field in properties) {
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

    // Field setters
    for (final field in properties) {
      _code
        ..write('  set ')
        ..write(field.nameInDart)
        ..write('(')
        ..write(field.typeWithNullabilitySuffix)
        ..write(' value) => ');

      if (field.isNullable) {
        _code
          ..write('value == null ? internal.removeValue(')
          ..write(escapeDartString(field.nameInData))
          ..write(') : ');
      }

      _code
        ..write('internal.setValue(value, key: ')
        ..write(escapeDartString(field.nameInData))
        ..writeln(');')
        ..writeln();
    }

    _code.writeln('}');
  }
}
