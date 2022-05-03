import 'dart:collection';

import 'package:meta/meta.dart';

import '../document.dart';
import '../errors.dart';
import 'annotations.dart';
import 'typed_object.dart';

// ignore: avoid_classes_with_only_static_members, camel_case_types
class InternalTypedDataHelpers {
  @internal
  static T property<T extends Object>({
    required DictionaryInterface internal,
    required String name,
    required String key,
  }) {
    final value = internal.value(key);
    if (value is T) {
      return value;
    }

    if (!internal.contains(key)) {
      throw TypedDataException(
        'Expected a value for property "$name" but there is none in the '
        'underlying data.',
        TypedDataErrorCode.dataMismatch,
      );
    }

    throw TypedDataException(
      'Expected a $T for property "$name" but the value in the underlying data '
      'is a ${value.runtimeType}.',
      TypedDataErrorCode.dataMismatch,
    );
  }

  @internal
  static T nullableProperty<T>({
    required DictionaryInterface internal,
    required String name,
    required String key,
  }) {
    final value = internal.value(key);
    if (value is T) {
      return value;
    }

    throw TypedDataException(
      'Expected a $T for property "$name" but the value in the underlying data '
      'is a ${value.runtimeType}.',
      TypedDataErrorCode.dataMismatch,
    );
  }

  @internal
  static T typedDataProperty<T>({
    required DictionaryInterface internal,
    required String name,
    required String key,
    required Factory<Dictionary, T> factory,
  }) {
    final data = InternalTypedDataHelpers.property<Dictionary>(
      internal: internal,
      name: name,
      key: key,
    );
    return factory(data);
  }

  @internal
  static T? nullableTypedDataProperty<T>({
    required DictionaryInterface internal,
    required String name,
    required String key,
    required Factory<Dictionary, T> factory,
  }) {
    final data = InternalTypedDataHelpers.nullableProperty<Dictionary?>(
      internal: internal,
      name: name,
      key: key,
    );
    return data == null ? null : factory(data);
  }

  @internal
  static T mutableTypedDataProperty<T>({
    required DictionaryInterface internal,
    required String name,
    required String key,
    required Factory<MutableDictionary, T> factory,
  }) {
    final data = InternalTypedDataHelpers.property<MutableDictionary>(
      internal: internal,
      name: name,
      key: key,
    );
    return factory(data);
  }

  @internal
  static T? mutableNullableTypedDataProperty<T>({
    required DictionaryInterface internal,
    required String name,
    required String key,
    required Factory<MutableDictionary, T> factory,
  }) {
    final data = InternalTypedDataHelpers.nullableProperty<MutableDictionary?>(
      internal: internal,
      name: name,
      key: key,
    );
    return data == null ? null : factory(data);
  }
}

// === Typed data model ========================================================

typedef Factory<I, D> = D Function(I internal);

abstract class TypedDataMetadata<I, MI, D, MD> {
  TypedDataMetadata({
    required this.dartName,
    required this.factory,
    required this.mutableFactory,
    this.typeMatcher,
  });

  final String dartName;
  final Factory<I, D> factory;
  final Factory<MI, MD> mutableFactory;
  final TypeMatcher? typeMatcher;

  Type get _type => D;
  Type get _mutableType => MD;
  late final TypeMatcherImpl? _typeMatcherImpl;

  void _addToRegistry(TypedDataRegistry registry) {
    _createTypeMatcherImpl();
  }

  void _createTypeMatcherImpl() {
    if (typeMatcher == null) {
      _typeMatcherImpl = null;
    } else {
      _typeMatcherImpl =
          TypeMatcherImpl.fromAnnotation(typeMatcher!, forType: this);
    }
  }
}

class TypedDictionaryMetadata<D, MD>
    extends TypedDataMetadata<Dictionary, MutableDictionary, D, MD> {
  TypedDictionaryMetadata({
    required String dartName,
    required Factory<Dictionary, D> factory,
    required Factory<MutableDictionary, MD> mutableFactory,
    TypeMatcher? typeMatcher,
  }) : super(
          dartName: dartName,
          factory: factory,
          mutableFactory: mutableFactory,
          typeMatcher: typeMatcher,
        );
}

class TypedDocumentMetadata<D, MD>
    extends TypedDataMetadata<Document, MutableDocument, D, MD> {
  TypedDocumentMetadata({
    required String dartName,
    required Factory<Document, D> factory,
    required Factory<MutableDocument, MD> mutableFactory,
    TypeMatcher? typeMatcher,
  }) : super(
          dartName: dartName,
          factory: factory,
          mutableFactory: mutableFactory,
          typeMatcher: typeMatcher,
        );
}

class TypedDataRegistry {
  TypedDataRegistry({
    Iterable<TypedDataMetadata> types = const [],
  })  : _types = List.unmodifiable(types),
        _dictionaryMetadataForType = HashMap.identity()
          ..addAll({
            for (final type in types)
              if (type is TypedDictionaryMetadata) type._type: type
          }),
        _documentMetadataForType = HashMap.identity()
          ..addAll({
            for (final type in types)
              if (type is TypedDocumentMetadata) type._type: type
          }),
        _documentMetadataForMutableType = HashMap.identity()
          ..addAll({
            for (final type in types)
              if (type is TypedDocumentMetadata) type._mutableType: type
          }) {
    for (final type in types) {
      type._addToRegistry(this);
    }
  }

  final List<TypedDataMetadata> _types;
  final Map<Type, TypedDictionaryMetadata> _dictionaryMetadataForType;
  final Map<Type, TypedDocumentMetadata> _documentMetadataForType;
  final Map<Type, TypedDocumentMetadata> _documentMetadataForMutableType;
  final Map<Type, Factory<Document, Object>?> _mutableDocumentFactoryCache =
      HashMap.identity();

  Factory<Dictionary, D>
      resolveDictionaryFactory<D extends TypedDictionaryObject>() {
    final dictionaryFactory = _dictionaryFactoryFor<D>();
    if (dictionaryFactory != null) {
      return dictionaryFactory;
    }

    throw _unknownTypeError(D);
  }

  Factory<Document, D> resolveDocumentFactory<D extends TypedDocumentObject>() {
    if (D == TypedDocumentObject || D == TypedMutableDocumentObject) {
      final dynamicFactory =
          dynamicDocumentFactory<D>(allowUnmatchedDocument: false);
      return (document) => dynamicFactory(document)!;
    }

    final documentFactory = _documentFactoryFor<D>();
    if (documentFactory != null) {
      return documentFactory;
    }

    final mutableDocumentFactory = _mutableDocumentFactoryFor<D>();
    if (mutableDocumentFactory != null) {
      return mutableDocumentFactory;
    }

    throw _unknownTypeError(D);
  }

  Factory<Document, D?> dynamicDocumentFactory<D extends TypedDocumentObject>({
    bool allowUnmatchedDocument = true,
  }) =>
      (document) {
        final matchedMetadata =
            _documentMetadataByTypedMatcher(document).toList();
        if (matchedMetadata.isNotEmpty) {
          if (matchedMetadata.length > 1) {
            final matchedTypeNames =
                matchedMetadata.map((metadata) => metadata.dartName).toList();
            throw TypedDataException(
              'Unable to resolve a document type because multiple document '
              'types matched the document: $matchedTypeNames',
              TypedDataErrorCode.unresolvableType,
            );
          }

          final metadata = matchedMetadata.first;
          if (D == TypedDocumentObject) {
            return metadata.factory(document) as D;
          } else {
            assert(D == TypedMutableDocumentObject);
            return metadata.mutableFactory(document.toMutable()) as D;
          }
        } else {
          if (allowUnmatchedDocument) {
            return null;
          } else {
            throw TypedDataException(
              'Unable to resolve a document type because no document types '
              'matched the document.',
              TypedDataErrorCode.unresolvableType,
            );
          }
        }
      };

  void checkDocumentType<D extends TypedDocumentObject>(Document doc) {
    if (D == TypedDocumentObject || D == TypedMutableDocumentObject) {
      // User is not specifying a concrete type, so we don't need to do a check.
      return;
    }

    final metadata =
        _documentMetadataForType[D] ?? _documentMetadataForMutableType[D];
    if (metadata == null) {
      throw _unknownTypeError(D);
    }

    late final matchingMetadata = _documentMetadataByTypedMatcher(doc)
        .map((metadata) => metadata.dartName)
        .toList();

    final typeMatcher = metadata._typeMatcherImpl;
    if (typeMatcher != null) {
      if (typeMatcher.isMatch(doc)) {
        return;
      }

      throw TypedDataException(
        'Expected to find a document that matches the type matcher of '
        '${metadata.dartName}, but found a document that matches the type '
        'matchers of the following types: $matchingMetadata',
        TypedDataErrorCode.typeMatchingConflict,
      );
    } else {
      assert(() {
        if (matchingMetadata.isNotEmpty) {
          throw TypedDataException(
            'Expected to find a document that matches no type matcher, '
            'but found a document that matches the type matchers of the '
            'following types: $matchingMetadata',
            TypedDataErrorCode.typeMatchingConflict,
          );
        }
        return true;
      }());
    }
  }

  void prepareDocumentForSave(TypedMutableDocumentObject document) {
    final metadata = _documentMetadataForMutableType[document.runtimeType];
    if (metadata == null) {
      throw _unknownTypeError(document.runtimeType);
    }

    final typeMatcher = metadata._typeMatcherImpl;
    if (typeMatcher == null) {
      return;
    }

    final internal = document.internal as MutableDocument;
    final isNew = internal.revisionId == null;
    if (isNew) {
      typeMatcher.makeMatch(internal);
    } else if (!typeMatcher.isMatch(internal)) {
      throw TypedDataException(
        'Document of type ${metadata.dartName} is not matching its '
        'TypeMatcher.',
        TypedDataErrorCode.typeMatchingConflict,
      );
    }
  }

  Iterable<TypedDocumentMetadata> _documentMetadataByTypedMatcher(
    Document document,
  ) =>
      _types.whereType<TypedDocumentMetadata>().where(
            (metadata) => metadata._typeMatcherImpl?.isMatch(document) == true,
          );

  Factory<Dictionary, D>?
      _dictionaryFactoryFor<D extends TypedDictionaryObject>() =>
          _dictionaryMetadataForType[D]?.factory as Factory<Dictionary, D>?;

  Factory<Document, D>? _documentFactoryFor<D extends TypedDocumentObject>() =>
      _documentMetadataForType[D]?.factory as Factory<Document, D>?;

  Factory<Document, D>?
      _mutableDocumentFactoryFor<D extends TypedDocumentObject>() =>
          _mutableDocumentFactoryCache.putIfAbsent(D, () {
            final factory = _documentMetadataForMutableType[D]?.mutableFactory
                as Factory<MutableDocument, D>?;
            if (factory == null) {
              return null;
            }

            return (doc) {
              if (doc is! MutableDocument) {
                doc = doc.toMutable();
              }
              return factory(doc);
            };
          }) as Factory<Document, D>?;
}

Exception _unknownTypeError(Type type) => TypedDataException(
      '$type is not a known typed data type.',
      TypedDataErrorCode.unknownType,
    );

// === TypeMatcherImpl =========================================================

@visibleForTesting
abstract class TypeMatcherImpl {
  TypeMatcherImpl();

  factory TypeMatcherImpl.fromAnnotation(
    TypeMatcher annotation, {
    required TypedDataMetadata forType,
  }) {
    if (annotation is ValueTypeMatcher) {
      return ValueTypeMatcherImpl(
        path: annotation.path,
        value: annotation.value ?? forType.dartName,
      );
    } else {
      throw UnimplementedError('Implementation for for $annotation');
    }
  }

  bool isMatch(DictionaryInterface data);

  void makeMatch(MutableDictionaryInterface data);
}

@visibleForTesting
class ValueTypeMatcherImpl extends TypeMatcherImpl {
  ValueTypeMatcherImpl({required this.path, required this.value});

  final List<Object> path;
  final Object value;

  @override
  bool isMatch(DictionaryInterface data) => _getValue(data) == value;

  @override
  void makeMatch(MutableDictionaryInterface data) => _setValue(data, value);

  Object? _getValue(DictionaryInterface data) => _getValueAtPath(data, path);

  Object? _getValueAtPath(DictionaryInterface data, List<Object> path) {
    Object? currentValue = data;

    for (var i = 0; i < path.length; i++) {
      final segment = path[i];

      if (segment is String) {
        if (currentValue is DictionaryInterface) {
          currentValue = currentValue.value(segment);
        } else {
          return null;
        }
      }

      if (segment is int) {
        if (currentValue is ArrayInterface) {
          currentValue = currentValue.length > segment
              ? currentValue.value(segment)
              : null;
        } else {
          return null;
        }
      }

      if (currentValue == null) {
        return null;
      }
    }

    return currentValue;
  }

  void _setValue(MutableDictionaryInterface data, Object value) {
    void checkCurrentValue(Object? currentValue) {
      if (currentValue != value) {
        throw TypedDataException(
          'ValueTypeMatcher: Expected value at path $path to not exist or be '
          '$value, but found $currentValue.',
          TypedDataErrorCode.dataMismatch,
        );
      }
    }

    final container = _getValueAtPath(data, path.sublist(0, path.length - 1));
    final lastSegment = path.last;
    if (lastSegment is String) {
      if (container is MutableDictionaryInterface) {
        if (container.contains(lastSegment)) {
          checkCurrentValue(container.value(lastSegment));
        } else {
          container.setValue(value, key: lastSegment);
        }
      } else {
        throw TypedDataException(
          'ValueTypeMatcher: Expected to find a Dictionary at path '
          '${path.sublist(0, path.length - 1)}, but found $container',
          TypedDataErrorCode.dataMismatch,
        );
      }
    } else if (lastSegment is int) {
      if (container is MutableArrayInterface) {
        if (container.length > lastSegment) {
          checkCurrentValue(container.value(lastSegment));
        } else if (container.length == lastSegment) {
          container.addValue(value);
        } else {
          throw TypedDataException(
            'ValueTypeMatcher: Expected to find an Array at path '
            '${path.sublist(0, path.length - 1)}, with at least $lastSegment '
            'elements, but found one with length ${container.length}.',
            TypedDataErrorCode.dataMismatch,
          );
        }
      } else {
        throw TypedDataException(
          'ValueTypeMatcher: Expected to find an Array at path '
          '${path.sublist(0, path.length - 1)}, but found $container',
          TypedDataErrorCode.dataMismatch,
        );
      }
    }
  }
}
