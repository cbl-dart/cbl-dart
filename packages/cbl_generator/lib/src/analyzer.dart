import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
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

// cbl annotation types
const _typedDictionaryType = TypeChecker.fromRuntime(TypedDictionary);
const _typedDocumentType = TypeChecker.fromRuntime(TypedDocument);
const _documentIdType = TypeChecker.fromRuntime(DocumentId);
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
        for (final type in types) await buildTypedDataClassModel(type.element!)
      ],
    );
  }

  Future<TypedDataClassModel> buildTypedDataClassModel(
    Element element, {
    TypedDataType? type,
  }) async {
    // Validate element is an abstract class.
    if (element is! ClassElement) {
      final annotationDescription = type == null
          ? '${_describeTypedDataAnnotation(TypedDataType.dictionary)} and '
              '${_describeTypedDataAnnotation(TypedDataType.document)}'
          : _describeTypedDataAnnotation(type);
      throw InvalidGenerationSourceError(
        '$annotationDescription can only be used on a class.',
        element: element,
      );
    }

    final annotatedClass = element;

    type ??= _checkTypedDataAnnotation(annotatedClass, type);

    final classNames = TypedDataClassNames(annotatedClass.displayName);

    await _checkAnnotatedTypedDataClass(
      annotatedClass,
      resolver,
      classNames,
      type,
    );

    final fields = _resolveTypedDataFields(annotatedClass, type);
    final documentIdField =
        fields.firstWhereOrNull((field) => field.isDocumentId);

    final documentIdFieldName =
        _resolveMetaDataFieldName<DocumentId, String>(annotatedClass);
    final sequenceFieldName =
        _resolveMetaDataFieldName<DocumentSequence, int>(annotatedClass);
    final revisionIdFieldName =
        _resolveMetaDataFieldName<DocumentRevisionId, String>(
      annotatedClass,
      nullable: true,
    );

    if (documentIdFieldName != null && documentIdField?.nameInDart != null) {
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
    final fieldNames = fields.map((field) => field.nameInDart).toSet();
    final conflictingFieldNames = metaDataFieldNames.intersection(fieldNames);
    if (conflictingFieldNames.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'Getters annotated with @DocumentId, @DocumentSequence, or '
        '@DocumentRevisionId are conflicting with constructor parameters: '
        '${conflictingFieldNames.join(', ')}',
        element: annotatedClass,
      );
    }

    return TypedDataClassModel(
      libraryUri: annotatedClass.librarySource.uri,
      type: type,
      classNames: classNames,
      fields: fields,
      idFieldName: documentIdFieldName ?? documentIdField?.nameInDart,
      sequenceFieldName: sequenceFieldName,
      revisionIdFieldName: revisionIdFieldName,
      typeMatcher: _resolveTypeMatcher(annotatedClass, classNames),
    );
  }

  TypedDataType _checkTypedDataAnnotation(
    ClassElement element,
    TypedDataType? expectedType,
  ) {
    final type = _readTypedDataType(element);
    if (type == null) {
      throw InvalidGenerationSourceError(
        'Expected class to be annotated with '
        '${_describeTypedDataAnnotation(TypedDataType.dictionary)} or '
        '${_describeTypedDataAnnotation(TypedDataType.document)}.',
        element: element,
      );
    } else if (expectedType != null && expectedType != type) {
      throw InvalidGenerationSourceError(
        'Expected class to be annotated with '
        '${_describeTypedDataAnnotation(expectedType)} but found '
        '${_describeTypedDataAnnotation(type)} instead.',
        element: element,
      );
    }
    return type;
  }

  TypedDataType? _readTypedDataType(ClassElement element) {
    if (_typedDictionaryType.hasAnnotationOfExact(element)) {
      return TypedDataType.dictionary;
    } else if (_typedDocumentType.hasAnnotationOfExact(element)) {
      return TypedDataType.document;
    } else {
      return null;
    }
  }

  Future<void> _checkAnnotatedTypedDataClass(
    ClassElement clazz,
    Resolver resolver,
    TypedDataClassNames typedDataClassNames,
    TypedDataType type,
  ) async {
    if (!clazz.isAbstract) {
      throw InvalidGenerationSourceError(
        '${_describeTypedDataAnnotation(type)} can only be used on an abstract '
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
    TypedDataClassNames classNames,
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

  List<TypedDataField> _resolveTypedDataFields(
    ClassElement clazz,
    TypedDataType type,
  ) =>
      clazz.unnamedConstructor!.parameters.map(
        (parameter) {
          if (!isExactlyOneOfTypes(parameter.type, _builtinSupportedTypes)) {
            final typeName =
                parameter.type.getDisplayString(withNullability: false);
            throw InvalidGenerationSourceError(
              'Unsupported type: $typeName',
              element: parameter,
            );
          }

          final annotations = parameter.metadata
              .map((annotation) => annotation.computeConstantValue())
              .map(ConstantReader.new);

          return TypedDataField(
            isDocumentId: _isDocumentIdField(parameter, annotations, type),
            type: parameter.type.getDisplayString(withNullability: false),
            isNullable:
                parameter.type.nullabilitySuffix == NullabilitySuffix.question,
            nameInDart: parameter.name,
            nameInData: parameter.name,
            isPositional: parameter.isPositional,
            isRequired:
                parameter.isRequiredNamed || parameter.isRequiredPositional,
          );
        },
      ).toList();

  bool _isDocumentIdField(
    ParameterElement parameter,
    Iterable<ConstantReader> annotations,
    TypedDataType type,
  ) {
    final annotation = annotations.firstWhereOrNull(
      (annotation) => annotation.instanceOf(_documentIdType),
    );

    if (annotation == null) {
      return false;
    }

    if (type == TypedDataType.dictionary) {
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

  String _describeTypedDataAnnotation(TypedDataType type) {
    switch (type) {
      case TypedDataType.dictionary:
        return '@TypedDictionary';
      case TypedDataType.document:
        return '@TypedDocument';
    }
  }
}
