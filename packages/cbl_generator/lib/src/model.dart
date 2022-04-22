import 'package:cbl/cbl.dart';

enum TypedDataType {
  document,
  dictionary,
}

class TypedDataClassModel {
  TypedDataClassModel({
    required this.libraryUri,
    required this.type,
    required this.classNames,
    required this.fields,
    this.idFieldName,
    this.sequenceFieldName,
    this.revisionIdFieldName,
    this.typeMatcher,
  });

  final Uri libraryUri;
  final TypedDataType type;
  final TypedDataClassNames classNames;
  final List<TypedDataField> fields;
  final String? idFieldName;
  final String? sequenceFieldName;
  final String? revisionIdFieldName;
  final TypeMatcher? typeMatcher;
}

class TypedDataClassNames {
  TypedDataClassNames(this.declaringClassName);

  final String declaringClassName;
  String get interfaceMixinName => '_\$$declaringClassName';
  String get implBaseName => '_${declaringClassName}ImplBase';
  String get immutableClassName => 'Immutable$declaringClassName';
  String get mutableClassName => 'Mutable$declaringClassName';
}

class TypedDataField {
  TypedDataField({
    required this.isDocumentId,
    required this.type,
    required this.isNullable,
    required this.nameInDart,
    required this.nameInData,
    required this.isPositional,
    required this.isRequired,
  });

  final bool isDocumentId;
  final String type;
  final bool isNullable;
  final String nameInDart;
  final String nameInData;
  final bool isPositional;
  final bool isRequired;

  String get typeWithNullabilitySuffix => isNullable ? '$type?' : type;
}

class TypedDatabaseModel {
  TypedDatabaseModel({
    required this.libraryUri,
    required this.declaringClassName,
    required this.types,
  });

  final Uri libraryUri;
  final String declaringClassName;
  final List<TypedDataClassModel> types;

  String get className => declaringClassName.replaceFirst(r'$', '');
}
