import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:cbl/cbl.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import 'analysis.dart';
import 'model.dart';

// dart:core types
const _stringType = TypeChecker.fromRuntime(String);
const _intType = TypeChecker.fromRuntime(int);
const _doubleType = TypeChecker.fromRuntime(double);
const _numType = TypeChecker.fromRuntime(num);
const _boolType = TypeChecker.fromRuntime(bool);
const _dateTimeType = TypeChecker.fromRuntime(DateTime);
const _listType = TypeChecker.fromRuntime(List);

// cbl annotation types
const _typedDictionaryType = TypeChecker.fromRuntime(TypedDictionary);
const _typedDocumentType = TypeChecker.fromRuntime(TypedDocument);
const _documentIdType = TypeChecker.fromRuntime(DocumentId);
const _typedPropertyType = TypeChecker.fromRuntime(TypedProperty);
const _valueTypeMatcherType = TypeChecker.fromRuntime(ValueTypeMatcher);
const _typedDatabaseType = TypeChecker.fromRuntime(TypedDatabase);

// cbl types
const _blobType = TypeChecker.fromRuntime(Blob);

const _builtinSupportedTypes = [
  _stringType,
  _intType,
  _doubleType,
  _numType,
  _boolType,
  _dateTimeType,
  _blobType,
];

class TypedDataAnalyzer {
  TypedDataAnalyzer(this.resolver);

  final Resolver resolver;

  Future<TypedDatabaseModel> buildTypedDatabaseModel(Element element) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@TypedDatabase can only be used on a class.',
        element: element,
      );
    }

    if (!element.displayName.startsWith(r'$')) {
      throw InvalidGenerationSourceError(
        r'Classes annotated with @TypedDatabase must start with $',
        element: element,
      );
    }

    final annotation = _typedDatabaseType.firstAnnotationOfExact(element);
    if (annotation == null) {
      throw InvalidGenerationSourceError(
        'Expected this class to be annotated with @TypedDatabase.',
        element: element,
      );
    }

    final types = ConstantReader(annotation)
        .read('types')
        .setValue
        .map((type) => type.toTypeValue()!)
        .toList();

    return TypedDatabaseModel(
      libraryUri: element.librarySource.uri,
      declaringClassName: element.displayName,
      types: [
        // ignore: deprecated_member_use
        for (final type in types) await buildTypedDataClassModel(type.element2!)
      ],
    );
  }

  Future<TypedDataObjectModel> buildTypedDataClassModel(
    Element element, {
    TypedDataObjectKind? kind,
  }) async {
    final cblLibrary =
        await resolver.libraryFor(AssetId.parse('cbl|lib/cbl.dart'));

    // Validate element is an abstract class.
    if (element is! ClassElement) {
      final annotationDescription = kind == null
          // ignore: prefer_interpolation_to_compose_strings
          ? _describeTypedDataAnnotation(TypedDataObjectKind.dictionary) +
              ' and ' +
              _describeTypedDataAnnotation(TypedDataObjectKind.document)
          : _describeTypedDataAnnotation(kind);
      throw InvalidGenerationSourceError(
        '$annotationDescription can only be used on a class.',
        element: element,
      );
    }

    final annotatedClass = element;

    kind ??= _checkTypedDataAnnotation(annotatedClass, kind);

    final classNames = TypedDataObjectClassNames(annotatedClass.displayName);

    await _checkAnnotatedTypedDataClass(
      annotatedClass,
      resolver,
      classNames,
      kind,
    );

    final fields =
        await _resolveTypedDataFields(annotatedClass, kind, cblLibrary);
    final documentIdField = fields
        .whereType<TypedDataMetadataField>()
        .firstWhereOrNull((field) => field.kind == DocumentMetadataKind.id);

    final documentIdFieldName =
        _resolveMetaDataFieldName<DocumentId, String>(annotatedClass);
    final sequenceFieldName =
        _resolveMetaDataFieldName<DocumentSequence, int>(annotatedClass);
    final revisionIdFieldName =
        _resolveMetaDataFieldName<DocumentRevisionId, String>(
      annotatedClass,
      nullable: true,
    );

    if (documentIdFieldName != null && documentIdField != null) {
      throw InvalidGenerationSourceError(
        '@DocumentId cannot both be used on a constructor parameter and a '
        'getter, within the same class.',
        element: annotatedClass,
      );
    }

    final metaDataFieldNames = [
      documentIdFieldName,
      sequenceFieldName,
      revisionIdFieldName,
    ].whereType<String>().toSet();
    final fieldNames = fields.map((field) => field.name).toSet();
    final conflictingFieldNames = metaDataFieldNames.intersection(fieldNames);
    if (conflictingFieldNames.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'Getters annotated with @DocumentId, @DocumentSequence, or '
        '@DocumentRevisionId are conflicting with constructor parameters: '
        '${conflictingFieldNames.join(', ')}',
        element: annotatedClass,
      );
    }

    if (documentIdFieldName != null) {
      fields.add(TypedDataMetadataField(
        name: documentIdFieldName,
        kind: DocumentMetadataKind.id,
        type: BuiltinScalarType(dartType: 'String'),
      ));
    }

    if (sequenceFieldName != null) {
      fields.add(TypedDataMetadataField(
        name: sequenceFieldName,
        kind: DocumentMetadataKind.sequence,
        type: BuiltinScalarType(dartType: 'int'),
      ));
    }

    if (revisionIdFieldName != null) {
      fields.add(TypedDataMetadataField(
        name: revisionIdFieldName,
        kind: DocumentMetadataKind.revisionId,
        type: BuiltinScalarType(dartType: 'String', isNullable: true),
      ));
    }

    return TypedDataObjectModel(
      libraryUri: annotatedClass.librarySource.uri,
      kind: kind,
      classNames: classNames,
      fields: fields,
      typeMatcher: _resolveTypeMatcher(annotatedClass, classNames),
    );
  }

  TypedDataObjectKind _checkTypedDataAnnotation(
    ClassElement element,
    TypedDataObjectKind? expectedKind,
  ) {
    final kind = _readTypedDataType(element);
    if (kind == null) {
      throw InvalidGenerationSourceError(
        'Expected class to be annotated with '
        '${_describeTypedDataAnnotation(TypedDataObjectKind.dictionary)} or '
        '${_describeTypedDataAnnotation(TypedDataObjectKind.document)}.',
        element: element,
      );
    } else if (expectedKind != null && expectedKind != kind) {
      throw InvalidGenerationSourceError(
        'Expected class to be annotated with '
        '${_describeTypedDataAnnotation(expectedKind)} but found '
        '${_describeTypedDataAnnotation(kind)} instead.',
        element: element,
      );
    }
    return kind;
  }

  TypedDataObjectKind? _readTypedDataType(ClassElement element) {
    if (_typedDictionaryType.hasAnnotationOfExact(element)) {
      return TypedDataObjectKind.dictionary;
    } else if (_typedDocumentType.hasAnnotationOfExact(element)) {
      return TypedDataObjectKind.document;
    } else {
      return null;
    }
  }

  Future<void> _checkAnnotatedTypedDataClass(
    ClassElement clazz,
    Resolver resolver,
    TypedDataObjectClassNames typedDataClassNames,
    TypedDataObjectKind kind,
  ) async {
    if (!clazz.isAbstract) {
      throw InvalidGenerationSourceError(
        '${_describeTypedDataAnnotation(kind)} can only be used on an abstract '
        'class.',
        element: clazz,
      );
    }

    final annotatedClassAstNode = (await resolver.astNodeFor(clazz))!;

    if (!classHasMixin(
      annotatedClassAstNode,
      typedDataClassNames.interfaceMixinName,
    )) {
      throw InvalidGenerationSourceError(
        'Class must mix in ${typedDataClassNames.interfaceMixinName}.',
        element: clazz,
      );
    }

    if (!classHasRedirectingUnnamedConstructor(
      annotatedClassAstNode,
      typedDataClassNames.mutableClassName,
    )) {
      throw InvalidGenerationSourceError(
        'Class must have a factory unnamed constructor which redirects to '
        '${typedDataClassNames.mutableClassName}.',
        element: clazz,
      );
    }
  }

  TypeMatcher? _resolveTypeMatcher(
    ClassElement clazz,
    TypedDataObjectClassNames classNames,
  ) {
    final annotationValue = _typedDocumentType.firstAnnotationOfExact(clazz);
    if (annotationValue == null) {
      return null;
    }

    final annotation = ConstantReader(annotationValue);
    final typeMatcher = annotation.read('typeMatcher');
    if (typeMatcher.isNull) {
      return null;
    }

    if (typeMatcher.instanceOf(_valueTypeMatcherType)) {
      final path =
          typeMatcher.read('path').listValue.map(ConstantReader.new).map((e) {
        if (e.isString) {
          return e.stringValue;
        } else if (e.isInt) {
          return e.intValue;
        }

        throw InvalidGenerationSourceError(
          '`typeMatcher.path` must be a List that only contains Strings and '
          'ints.',
          element: clazz,
        );
      }).toList();

      if (path.isEmpty) {
        throw InvalidGenerationSourceError(
          '`typeMatcher.path` must be a List that contains at least one '
          'element.',
          element: clazz,
        );
      }

      final value = typeMatcher.read('value');
      final String? effectiveValue;
      if (value.isString) {
        effectiveValue = value.stringValue;
      } else if (value.isNull) {
        effectiveValue = null;
      } else {
        throw InvalidGenerationSourceError(
          '`typeMatcher.value` must be a String or null.',
          element: clazz,
        );
      }

      return ValueTypeMatcher(
        path: path,
        value: effectiveValue,
      );
    }

    return null;
  }

  Future<List<TypedDataObjectField>> _resolveTypedDataFields(
    ClassElement clazz,
    TypedDataObjectKind kind,
    LibraryElement cblLibrary,
  ) async =>
      Future.wait(clazz.unnamedConstructor!.parameters.map(
        (parameter) async {
          final annotations = parameter.metadata
              .map((annotation) => annotation.computeConstantValue())
              .map(ConstantReader.new);

          final typedPropertyAnnotation = annotations.firstWhereOrNull(
            (annotation) => annotation.instanceOf(_typedPropertyType),
          );
          String? customProperty;
          String? defaultValueCode;
          ScalarConverterInfo? scalarConverter;
          if (typedPropertyAnnotation != null) {
            final propertyConstant = typedPropertyAnnotation.peek('property');
            if (propertyConstant != null) {
              customProperty = propertyConstant.stringValue;
            }

            final defaultValueConstant =
                typedPropertyAnnotation.peek('defaultValue');
            if (defaultValueConstant != null) {
              defaultValueCode = defaultValueConstant.stringValue;
            }

            final converterConstant = typedPropertyAnnotation.peek('converter');
            if (converterConstant != null) {
              final scalarConverterClass = cblLibrary.exportNamespace
                  .get('ScalarConverter')! as ClassElement;
              final convertedType = converterConstant.objectValue.type!
                  .asInstanceOf(scalarConverterClass)!
                  .typeArguments
                  .first;
              scalarConverter = ScalarConverterInfo(
                type: convertedType,
                code: converterConstant.code,
              );
            }
          }

          final type = _resolveTypedDataType(
            parameter,
            propertyConverter: scalarConverter,
          );

          final constructorParameter = ConstructorParameter(
            type: type,
            isPositional: parameter.isPositional,
            isRequired:
                parameter.isRequiredNamed || parameter.isRequiredPositional,
            documentationComment:
                await parameter.documentationCommentValue(resolver),
          );

          final isDocumentId = _isDocumentIdField(parameter, annotations, kind);
          if (isDocumentId) {
            return TypedDataMetadataField(
              kind: DocumentMetadataKind.id,
              type: (type as BuiltinScalarType).withNullability(false),
              name: parameter.name,
              constructorParameter: constructorParameter,
            );
          }

          return TypedDataObjectProperty(
            type: type,
            name: parameter.name,
            property: customProperty ?? parameter.name,
            constructorParameter: constructorParameter,
            defaultValueCode: defaultValueCode,
          );
        },
      ));

  bool _isDocumentIdField(
    ParameterElement parameter,
    Iterable<ConstantReader> annotations,
    TypedDataObjectKind kind,
  ) {
    final annotation = annotations.firstWhereOrNull(
      (annotation) => annotation.instanceOf(_documentIdType),
    );

    if (annotation == null) {
      return false;
    }

    if (kind == TypedDataObjectKind.dictionary) {
      throw InvalidGenerationSourceError(
        '@DocumentId cannot be used in a dictionary, and only in a '
        'document.',
        element: parameter,
      );
    }

    if (!_stringType.isExactlyType(parameter.type)) {
      throw InvalidGenerationSourceError(
        '@DocumentId must be used on a String field.',
        element: parameter,
      );
    }

    return true;
  }

  String? _resolveMetaDataFieldName<Annotation, Type>(
    ClassElement clazz, {
    bool nullable = false,
  }) {
    final annotationTypeChecker = TypeChecker.fromRuntime(Annotation);
    final typeTypeChecker = TypeChecker.fromRuntime(Type);
    final nullabilitySuffix =
        nullable ? NullabilitySuffix.question : NullabilitySuffix.none;

    return clazz.accessors.firstWhereOrNull((element) {
      if (!element.isGetter) {
        return false;
      }
      if (!annotationTypeChecker.hasAnnotationOfExact(element)) {
        return false;
      }
      if (!typeTypeChecker.isExactlyType(element.returnType) ||
          element.returnType.nullabilitySuffix != nullabilitySuffix) {
        throw InvalidGenerationSourceError(
          '@$Annotation must be used on a getter which returns a $Type'
          '${nullable ? '?' : ''}.',
          element: element,
        );
      }
      return true;
    })?.displayName;
  }

  String _describeTypedDataAnnotation(TypedDataObjectKind kind) {
    switch (kind) {
      case TypedDataObjectKind.dictionary:
        return '@TypedDictionary';
      case TypedDataObjectKind.document:
        return '@TypedDocument';
    }
  }

  TypedDataType _resolveTypedDataType(
    VariableElement element, {
    ScalarConverterInfo? propertyConverter,
  }) {
    TypedDataType? resolve(DartType type) {
      final typeName = type.getDisplayString(withNullability: false);
      final isNullable = type.nullabilitySuffix == NullabilitySuffix.question;

      if (propertyConverter != null) {
        if (TypeChecker.fromStatic(propertyConverter.type)
            .isExactlyType(type)) {
          return CustomScalarType(
            dartType: typeName,
            isNullable: isNullable,
            converter: propertyConverter,
          );
        }
      } else {
        if (isExactlyOneOfTypes(type, _builtinSupportedTypes)) {
          return BuiltinScalarType(
            dartType: typeName,
            isNullable: isNullable,
          );
        }

        // TODO(blaugold): Remove this ignore once the analyzer dependency is
        // upgraded
        // ignore: deprecated_member_use
        if (type.element2 is EnumElement) {
          return CustomScalarType(
            dartType: typeName,
            isNullable: isNullable,
            converter: ScalarConverterInfo(
              type: type,
              code: 'const EnumNameConverter($typeName.values)',
            ),
          );
        }

        if (_isTypedDataObject(type)) {
          return TypedDataObjectType(
            dartType: typeName,
            isNullable: isNullable,
          );
        }
      }

      if (_listType.isExactlyType(type)) {
        final elementType = (type as ParameterizedType).typeArguments.first;
        final resolvedElementType = resolve(elementType);
        if (resolvedElementType == null) {
          return null;
        }
        return TypedDataListType(
          isNullable: isNullable,
          elementType: resolvedElementType,
        );
      }

      return null;
    }

    final type = element.type;
    final resolvedType = resolve(type);
    if (resolvedType != null) {
      return resolvedType;
    }

    final typeName = type.getDisplayString(withNullability: false);

    if (propertyConverter != null) {
      throw InvalidGenerationSourceError(
        '$typeName is not, nor contains as a type argument, a type that '
        "is exactly the type of the property's converter.",
        element: element,
      );
    }

    throw InvalidGenerationSourceError(
      'Unsupported type: $typeName',
      element: element,
    );
  }
}

bool _isTypedDataObject(DartType type) {
  if (type is InterfaceType) {
    // ignore: deprecated_member_use
    return _typedDictionaryType.hasAnnotationOfExact(type.element2) ||
        // ignore: deprecated_member_use
        _typedDocumentType.hasAnnotationOfExact(type.element2);
  }

  return false;
}
