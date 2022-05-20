import 'dart:collection';

import 'package:meta/meta.dart' hide internal;

import '../document.dart';
import '../errors.dart';
import 'adapter.dart';
import 'annotations.dart';
import 'typed_object.dart';

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
    required super.dartName,
    required super.factory,
    required super.mutableFactory,
    super.typeMatcher,
  });
}

class TypedDocumentMetadata<D, MD>
    extends TypedDataMetadata<Document, MutableDocument, D, MD> {
  TypedDocumentMetadata({
    required super.dartName,
    required super.factory,
    required super.mutableFactory,
    super.typeMatcher,
  });
}

class TypedDataRegistry extends TypedDataAdapter {
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

  @override
  Factory<Dictionary, D>
      dictionaryFactoryForType<D extends TypedDictionaryObject>() {
    final dictionaryFactory = _dictionaryFactoryFor<D>();
    if (dictionaryFactory != null) {
      return dictionaryFactory;
    }

    throw _unknownTypeError(D);
  }

  @override
  Factory<Document, D> documentFactoryForType<D extends TypedDocumentObject>() {
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

  @override
  Factory<Document, D?>
      dynamicDocumentFactoryForType<D extends TypedDocumentObject>({
    bool allowUnmatchedDocument = true,
  }) =>
          (document) {
            final matchedMetadata =
                _documentMetadataByTypedMatcher(document).toList();
            if (matchedMetadata.isNotEmpty) {
              if (matchedMetadata.length > 1) {
                final matchedTypeNames = matchedMetadata
                    .map((metadata) => metadata.dartName)
                    .toList();
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

  @override
  void checkDocumentIsOfType<D extends TypedDocumentObject>(Document document) {
    final metadata =
        _documentMetadataForType[D] ?? _documentMetadataForMutableType[D];
    if (metadata == null) {
      throw _unknownTypeError(D);
    }

    late final matchingMetadata = _documentMetadataByTypedMatcher(document)
        .map((metadata) => metadata.dartName)
        .toList();

    final typeMatcher = metadata._typeMatcherImpl;
    if (typeMatcher != null) {
      if (typeMatcher.isMatch(document)) {
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

  @override
  void willSaveDocument(TypedMutableDocumentObject document) {
    _applyTypeMatcherToDocument(document);
  }

  void _applyTypeMatcherToDocument(TypedMutableDocumentObject document) {
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
            (metadata) => metadata._typeMatcherImpl?.isMatch(document) ?? false,
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
