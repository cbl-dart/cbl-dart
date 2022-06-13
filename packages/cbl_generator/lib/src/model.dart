import 'package:analyzer/dart/element/type.dart';
import 'package:cbl/cbl.dart';
import 'package:collection/collection.dart';

enum TypedDataObjectKind {
  document,
  dictionary,
}

class TypedDataObjectModel {
  TypedDataObjectModel({
    required this.libraryUri,
    required this.kind,
    required this.classNames,
    required this.fields,
    this.typeMatcher,
  });

  final Uri libraryUri;
  final TypedDataObjectKind kind;
  final TypedDataObjectClassNames classNames;
  final List<TypedDataObjectField> fields;
  final TypeMatcher? typeMatcher;

  late final metadataFields =
      fields.whereType<TypedDataMetadataField>().toList();

  late final documentIdField = _documentMetadataField(DocumentMetadataKind.id);

  late final documentSequenceField =
      _documentMetadataField(DocumentMetadataKind.sequence);

  late final documentRevisionIdField =
      _documentMetadataField(DocumentMetadataKind.revisionId);

  late final properties = fields.whereType<TypedDataObjectProperty>().toList();

  TypedDataMetadataField? _documentMetadataField(DocumentMetadataKind kind) =>
      metadataFields.firstWhereOrNull((field) => field.kind == kind);
}

class TypedDataObjectClassNames {
  TypedDataObjectClassNames(this.declaringClassName);

  final String declaringClassName;
  String get interfaceMixinName => '_\$$declaringClassName';
  String get implBaseName => '_${declaringClassName}ImplBase';
  String get immutableClassName => 'Immutable$declaringClassName';
  String get mutableClassName => 'Mutable$declaringClassName';
}

abstract class TypedDataObjectField {
  TypedDataObjectField({
    required this.type,
    required this.name,
    this.constructorParameter,
  });

  final TypedDataType type;
  final String name;
  final ConstructorParameter? constructorParameter;

  bool get isNullable => type.isNullable;
}

enum DocumentMetadataKind {
  id,
  sequence,
  revisionId,
}

class TypedDataMetadataField extends TypedDataObjectField {
  TypedDataMetadataField({
    required super.type,
    required super.name,
    required this.kind,
    super.constructorParameter,
  });

  final DocumentMetadataKind kind;
}

class TypedDataObjectProperty extends TypedDataObjectField {
  TypedDataObjectProperty({
    required super.type,
    required super.name,
    required this.property,
    required ConstructorParameter super.constructorParameter,
    this.defaultValueCode,
  });

  @override
  ConstructorParameter get constructorParameter => super.constructorParameter!;

  final String property;
  final String? defaultValueCode;
}

class ConstructorParameter {
  ConstructorParameter({
    required this.type,
    required this.isPositional,
    required this.isRequired,
    this.documentationComment,
  });

  final TypedDataType type;
  final bool isPositional;
  final bool isRequired;
  final String? documentationComment;
}

class TypedDatabaseModel {
  TypedDatabaseModel({
    required this.libraryUri,
    required this.declaringClassName,
    required this.types,
  });

  final Uri libraryUri;
  final String declaringClassName;
  final List<TypedDataObjectModel> types;

  String get className => declaringClassName.replaceFirst(r'$', '');
}

abstract class TypedDataType {
  TypedDataType({
    required this.dartType,
    required this.mutableDartType,
    required this.isNullable,
    required this.isCached,
  });

  final String dartType;

  final String mutableDartType;

  /// Whether the type is nullable.
  final bool isNullable;

  /// Whether values of this type should be cached instead of re-read every time
  /// they are accessed.
  final bool isCached;

  String get dartTypeWithNullability => isNullable ? '$dartType?' : dartType;
  String get mutableDartTypeWithNullability =>
      isNullable ? '$mutableDartType?' : mutableDartType;
}

class BuiltinScalarType extends TypedDataType {
  BuiltinScalarType({required super.dartType, super.isNullable = false})
      : super(mutableDartType: dartType, isCached: false);

  // ignore: avoid_positional_boolean_parameters
  BuiltinScalarType withNullability(bool isNullable) => BuiltinScalarType(
        dartType: dartType,
        isNullable: isNullable,
      );
}

class CustomScalarType extends TypedDataType {
  CustomScalarType({
    required super.dartType,
    required super.isNullable,
    required this.converter,
  }) : super(mutableDartType: dartType, isCached: false);

  final ScalarConverterInfo converter;
}

class ScalarConverterInfo {
  ScalarConverterInfo({required this.type, required this.code});

  final DartType type;
  final String code;
}

class TypedDataObjectType extends TypedDataType {
  TypedDataObjectType({required super.dartType, required super.isNullable})
      : super(mutableDartType: 'Mutable$dartType', isCached: true);

  late final classNames = TypedDataObjectClassNames(dartType);
}

class TypedDataListType extends TypedDataType {
  TypedDataListType({required super.isNullable, required this.elementType})
      : super(
          dartType: 'List<${elementType.dartType}>',
          mutableDartType: 'TypedDataList<${elementType.mutableDartType}, '
              '${elementType.dartType}>',
          isCached: true,
        );

  final TypedDataType elementType;
}
