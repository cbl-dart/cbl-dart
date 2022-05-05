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
    required this.nameInDart,
    this.constructorParameter,
  });

  final TypedDataType type;
  final String nameInDart;
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
    required TypedDataType type,
    required String nameInDart,
    required this.kind,
    ConstructorParameter? constructorParameter,
  }) : super(
          type: type,
          nameInDart: nameInDart,
          constructorParameter: constructorParameter,
        );

  final DocumentMetadataKind kind;
}

class TypedDataObjectProperty extends TypedDataObjectField {
  TypedDataObjectProperty({
    required TypedDataType type,
    required String nameInDart,
    required this.nameInData,
    required ConstructorParameter constructorParameter,
  }) : super(
          type: type,
          nameInDart: nameInDart,
          constructorParameter: constructorParameter,
        );

  @override
  ConstructorParameter get constructorParameter => super.constructorParameter!;

  final String nameInData;
}

class ConstructorParameter {
  ConstructorParameter({
    required this.type,
    required this.isPositional,
    required this.isRequired,
  });

  final TypedDataType type;
  final bool isPositional;
  final bool isRequired;
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

  /// Whether values of this type should be cached instead of re-read every
  /// time they are accessed.
  final bool isCached;

  String get dartTypeWithNullability => isNullable ? '$dartType?' : dartType;
  String get mutableDartTypeWithNullability =>
      isNullable ? '$mutableDartType?' : mutableDartType;
}

class BuiltinScalarType extends TypedDataType {
  BuiltinScalarType({
    required String dartType,
    bool isNullable = false,
  }) : super(
          dartType: dartType,
          mutableDartType: dartType,
          isNullable: isNullable,
          isCached: false,
        );

  // ignore: avoid_positional_boolean_parameters
  BuiltinScalarType withNullability(bool isNullable) => BuiltinScalarType(
        dartType: dartType,
        isNullable: isNullable,
      );
}

class TypedDataObjectType extends TypedDataType {
  TypedDataObjectType({
    required String dartType,
    required bool isNullable,
  }) : super(
          dartType: dartType,
          mutableDartType: 'Mutable$dartType',
          isNullable: isNullable,
          isCached: true,
        );

  late final classNames = TypedDataObjectClassNames(dartType);
}

class TypedDataListType extends TypedDataType {
  TypedDataListType({
    required bool isNullable,
    required this.elementType,
  }) : super(
          dartType: 'List<${elementType.dartType}>',
          mutableDartType: 'TypedDataList<${elementType.mutableDartType}, '
              '${elementType.dartType}>',
          isNullable: isNullable,
          isCached: true,
        );

  final TypedDataType elementType;
}
