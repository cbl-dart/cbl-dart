import 'package:collection/collection.dart';

import '../document.dart';
import '../support/utils.dart';
import 'annotations.dart';
import 'typed_object.dart';

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
  _TypeMatcherImpl? _cachedTypeMatcherImpl;

  _TypeMatcherImpl? _typeMatcherImpl() {
    final typeMatcher = this.typeMatcher;
    if (typeMatcher == null) {
      return null;
    }

    return _cachedTypeMatcherImpl ??=
        _TypeMatcherImpl.fromAnnotation(typeMatcher, forType: this);
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
  }) : _types = List.unmodifiable(types);

  final List<TypedDataMetadata> _types;

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
      return _dynamicDocumentFactory();
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

  void checkDocumentType<D extends TypedDocumentObject>(Document doc) {
    if (D == TypedDocumentObject || D == TypedMutableDocumentObject) {
      // User is not specifying a concrete type, so we can't check.
      return;
    }

    final metadata =
        _documentMetadataForType(D) ?? _documentMetadataForMutableType(D);
    if (metadata == null) {
      throw _unknownTypeError(D);
    }

    final typeMatcher = metadata._typeMatcherImpl();
    if (typeMatcher != null) {
      if (typeMatcher.isMatch(doc)) {
        return;
      }

      final matchingMetadata = _documentMetadataByTypedMatcher(doc)
          .map((metadata) => metadata.dartName)
          .toList();
      throw StateError(
        'Expected to find a document that matches the type matcher of '
        '${metadata.dartName}, but found a document that matches the type '
        'matchers of the following types: $matchingMetadata',
      );
    } else {
      assert(() {
        final matchingMetadata = _documentMetadataByTypedMatcher(doc)
            .map((metadata) => metadata.dartName)
            .toList();
        if (matchingMetadata.isNotEmpty) {
          throw StateError(
            'Expected to find a document that matches no type matcher, '
            'but found a document that matches the type matchers of the '
            'following types: $matchingMetadata',
          );
        }
        return true;
      }());
    }
  }

  void prepareDocumentForSave(TypedMutableDocumentObject document) {
    final metadata = _documentMetadataForMutableType(document.runtimeType);
    if (metadata == null) {
      throw _unknownTypeError(document.runtimeType);
    }

    final typeMatcher = metadata._typeMatcherImpl();
    if (typeMatcher == null) {
      return;
    }

    final internal = document.internal as MutableDocument;
    final isNew = internal.revisionId == null;
    if (isNew) {
      typeMatcher.makeMatch(internal);
    } else if (!typeMatcher.isMatch(internal)) {
      throw StateError(
        'Document of type ${metadata.dartName} is not matching its '
        'TypeMatcher.',
      );
    }
  }

  TypedDictionaryMetadata? _dictionaryMetadataForType(Type type) => _types
      .whereType<TypedDictionaryMetadata>()
      .firstWhereOrNull((metadata) => metadata._type == type);

  TypedDocumentMetadata? _documentMetadataForType(Type type) => _types
      .whereType<TypedDocumentMetadata>()
      .firstWhereOrNull((metadata) => metadata._type == type);

  TypedDocumentMetadata? _documentMetadataForMutableType(Type type) => _types
      .whereType<TypedDocumentMetadata>()
      .firstWhereOrNull((metadata) => metadata._mutableType == type);

  Iterable<TypedDocumentMetadata> _documentMetadataByTypedMatcher(
    Document document,
  ) =>
      _types.whereType<TypedDocumentMetadata>().where(
            (metadata) =>
                metadata._typeMatcherImpl()?.isMatch(document) == true,
          );

  Factory<Dictionary, D>?
      _dictionaryFactoryFor<D extends TypedDictionaryObject>() =>
          _dictionaryMetadataForType(D)?.factory as Factory<Dictionary, D>?;

  Factory<Document, D>? _documentFactoryFor<D extends TypedDocumentObject>() =>
      _documentMetadataForType(D)?.factory as Factory<Document, D>?;

  Factory<Document, D>?
      _mutableDocumentFactoryFor<D extends TypedDocumentObject>() =>
          (_documentMetadataForMutableType(D)?.mutableFactory
                  as Factory<MutableDocument, D>?)
              ?.let((fn) => (doc) {
                    if (doc is! MutableDocument) {
                      doc = doc.toMutable();
                    }
                    return fn(doc);
                  });

  Factory<Document, D>
      _dynamicDocumentFactory<D extends TypedDocumentObject>() => (document) {
            final matchedMetadata =
                _documentMetadataByTypedMatcher(document).toList();
            if (matchedMetadata.isNotEmpty) {
              if (matchedMetadata.length > 1) {
                final matchedTypeNames = matchedMetadata
                    .map((metadata) => metadata.dartName)
                    .toList();
                throw StateError(
                  'Unable to resolve a document type because multiple document '
                  'types matched the document: $matchedTypeNames',
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
              throw StateError(
                'Unable to resolve a document type because no document types '
                'matched the document.',
              );
            }
          };
}

StateError _unknownTypeError(Type type) => StateError(
      '$type is not a known typed data type. Ensure it has'
      ' been registered in the @TypedDatabase annotation.',
    );

// === TypeMatcherImpl =========================================================

abstract class _TypeMatcherImpl {
  _TypeMatcherImpl();

  factory _TypeMatcherImpl.fromAnnotation(
    TypeMatcher annotation, {
    required TypedDataMetadata forType,
  }) {
    if (annotation is ValueTypeMatcher) {
      return _ValueTypeMatcherImpl(
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

class _ValueTypeMatcherImpl extends _TypeMatcherImpl {
  _ValueTypeMatcherImpl({required this.path, required this.value});

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
          currentValue = currentValue.value(segment);
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
      if (currentValue != null && currentValue != value) {
        throw StateError(
          'ValueTypeMatcher: Expected value at path $path to be null or '
          '$value, but found $currentValue.',
        );
      }
    }

    final container = _getValueAtPath(data, path.sublist(0, path.length - 1));
    final lastSegment = path.last;
    if (lastSegment is String) {
      if (container is MutableDictionaryInterface) {
        checkCurrentValue(container.value(lastSegment));
        container.setValue(value, key: lastSegment);
      } else {
        throw StateError(
          'ValueTypeMatcher: Expected to find a Dictionary at path '
          '${path.sublist(0, path.length - 1)}, but found $container',
        );
      }
    } else if (lastSegment is int) {
      if (container is MutableArrayInterface) {
        if (container.length > lastSegment) {
          checkCurrentValue(container.value(lastSegment));
          container.setValue(value, at: lastSegment);
        } else if (container.length == lastSegment) {
          container.addValue(value);
        } else {
          throw StateError(
            'ValueTypeMatcher: Expected to find an Array at path '
            '${path.sublist(0, path.length - 1)}, with at least $lastSegment '
            'elements, but found one with length ${container.length}.',
          );
        }
      } else {
        throw StateError(
          'ValueTypeMatcher: Expected to find an Array at path '
          '${path.sublist(0, path.length - 1)}, but found $container',
        );
      }
    }
  }
}
