import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart' hide internal;
import 'package:meta/meta.dart' as meta;

import '../document.dart';
import '../errors.dart';
import 'adapter.dart';
import 'annotations.dart';
import 'conversion.dart';
import 'typed_object.dart';

// === Generator helpers =======================================================

// ignore: avoid_classes_with_only_static_members
class InternalTypedDataHelpers {
  // Converters
  @meta.internal
  static const stringConverter = IdentityConverter<String>();
  @meta.internal
  static const intConverter = IdentityConverter<int>();
  @meta.internal
  static const doubleConverter = IdentityConverter<double>();
  @meta.internal
  static const numConverter = IdentityConverter<num>();
  @meta.internal
  static const boolConverter = IdentityConverter<bool>();
  @meta.internal
  static const blobConverter = IdentityConverter<Blob>();
  @meta.internal
  static const dateTimeConverter = DateTimeConverter();

  // Read helpers
  @meta.internal
  static T readProperty<T>({
    required DictionaryInterface internal,
    required String name,
    required String key,
    required ToTyped<T> converter,
  }) {
    final value = internal.value(key);
    if (value == null) {
      if (!internal.contains(name)) {
        throw TypedDataException(
          'Expected a value for property "$name" but there is none in the '
          'underlying data.',
          TypedDataErrorCode.dataMismatch,
        );
      } else {
        throw TypedDataException(
          'Expected a value for property "$name" but found "null" in the '
          'underlying data.',
          TypedDataErrorCode.dataMismatch,
        );
      }
    }

    try {
      return converter.toTyped(value);
    } on UnexpectedTypeException catch (e) {
      throw TypedDataException(
        'At property "$name": $e',
        TypedDataErrorCode.dataMismatch,
        e,
      );
    }
  }

  @meta.internal
  static T? readNullableProperty<T>({
    required DictionaryInterface internal,
    required String name,
    required String key,
    required ToTyped<T> converter,
  }) {
    final value = internal.value(key);
    if (value == null) {
      return null;
    }

    try {
      return converter.toTyped(value);
    } on UnexpectedTypeException catch (e) {
      throw TypedDataException(
        'At property "$name": $e',
        TypedDataErrorCode.dataMismatch,
        e,
      );
    }
  }

  // Write helpers
  @meta.internal
  static void writeProperty<T>({
    required MutableDictionaryInterface internal,
    required T value,
    required String key,
    required ToUntyped<T> converter,
  }) {
    internal.setValue(converter.toUntyped(value), key: key);
  }

  @meta.internal
  static void writeNullableProperty<T>({
    required MutableDictionaryInterface internal,
    required T? value,
    required String key,
    required ToUntyped<T> converter,
  }) {
    if (value == null) {
      internal.removeValue(key);
    } else {
      internal.setValue(converter.toUntyped(value), key: key);
    }
  }

  static String renderString({
    required String? indent,
    required String className,
    required Map<String, Object?> fields,
  }) {
    if (indent == null) {
      return [
        className,
        '(',
        [for (final entry in fields.entries) '${entry.key}: ${entry.value}']
            .join(', '),
        ')',
      ].join();
    } else {
      final buffer = StringBuffer()
        ..write(className)
        ..writeln('(');
      for (final entry in fields.entries) {
        buffer
          ..write(indent)
          ..write(entry.key)
          ..write(': ');

        final lines = entry.value.renderStringIndented(indent);

        buffer.write(lines[0]);
        for (final line in lines.skip(1)) {
          buffer
            ..writeln()
            ..write(indent)
            ..write(line);
        }
        buffer.writeln(',');
      }
      buffer.write(')');
      return buffer.toString();
    }
  }
}

extension on Object? {
  List<String> renderStringIndented(String indent) {
    final value = this;
    final String valueString;
    if (value == null) {
      valueString = 'null';
    } else if (value is TypedDictionaryObject) {
      valueString = value.toString(indent: indent);
    } else if (value is TypedDataList) {
      valueString = value.toString(indent: indent);
    } else {
      valueString = value.toString();
    }
    return valueString.split('\n');
  }
}

// === TypedDataList ===========================================================

abstract class _TypedDataListBase<T extends E, E, I extends Array>
    with ListMixin<T>, TypedDataListToString
    implements TypedDataList<T, E> {
  _TypedDataListBase({
    required this.internal,
    required DataConverter<T, E> converter,
    required bool isNullable,
  })  : _converter = converter,
        _isNullable = isNullable;

  @override
  final I internal;
  final DataConverter<T, E> _converter;
  final bool _isNullable;

  @override
  int get length => internal.length;

  @override
  T operator [](int index) {
    final value = internal.value(index);
    if (value == null) {
      if (_isNullable) {
        return null as T;
      } else {
        throw TypedDataException(
          'Expected a value for element $index but found "null" in the '
          'underlying data.',
          TypedDataErrorCode.dataMismatch,
        );
      }
    }

    try {
      return _converter.toTyped(value);
    } on UnexpectedTypeException catch (e) {
      throw TypedDataException(
        'At index $index: $e',
        TypedDataErrorCode.dataMismatch,
        e,
      );
    }
  }
}

class ImmutableTypedDataList<T extends E, E>
    extends _TypedDataListBase<T, E, Array> {
  ImmutableTypedDataList({
    required Array internal,
    required DataConverter<T, E> converter,
    required bool isNullable,
  }) : super(internal: internal, converter: converter, isNullable: isNullable);

  @override
  void operator []=(int index, E value) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  set length(int newLength) {
    throw UnsupportedError('Cannot change the length of an immutable list');
  }

  @override
  set first(E element) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  set last(E element) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  void add(E element) {
    throw UnsupportedError('Cannot add to an immutable list');
  }

  @override
  void insert(int index, E element) {
    throw UnsupportedError('Cannot add to an immutable list');
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    throw UnsupportedError('Cannot add to an immutable list');
  }

  @override
  void addAll(Iterable<E> iterable) {
    throw UnsupportedError('Cannot add to an immutable list');
  }

  @override
  bool remove(Object? element) {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  void removeWhere(bool Function(T element) test) {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  void retainWhere(bool Function(T element) test) {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  void sort([Comparator<T>? compare]) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  void shuffle([Random? random]) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  void clear() {
    throw UnsupportedError('Cannot clear an immutable list');
  }

  @override
  T removeAt(int index) {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  T removeLast() {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    throw UnsupportedError('Cannot modify an immutable list');
  }

  @override
  void removeRange(int start, int end) {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    throw UnsupportedError('Cannot remove from an immutable list');
  }

  @override
  void fillRange(int start, int end, [E? fill]) {
    throw UnsupportedError('Cannot modify an immutable list');
  }
}

class MutableTypedDataList<T extends E, E>
    extends _TypedDataListBase<T, E, MutableArray> {
  MutableTypedDataList({
    required MutableArray internal,
    required DataConverter<T, E> converter,
    required bool isNullable,
  }) : super(internal: internal, converter: converter, isNullable: isNullable);

  T _promote(E value) => _converter.promote(value);

  @override
  set length(int newLength) {
    final oldLength = internal.length;
    final delta = oldLength - newLength;
    if (delta > 0) {
      for (var i = 0; i < delta; i++) {
        internal.removeValue(oldLength - 1 - i);
      }
    } else if (delta < 0) {
      for (var i = 0; i < delta; i++) {
        internal.addValue(null);
      }
    }
  }

  @override
  void operator []=(int index, E value) {
    internal.setValue(_converter.toUntyped(_promote(value)), at: index);
  }

  @override
  void add(E element) {
    internal.addValue(_converter.toUntyped(_promote(element)));
  }

  @override
  void addAll(Iterable<E> iterable) {
    for (final element in iterable) {
      internal.addValue(_converter.toUntyped(_promote(element)));
    }
  }

  @override
  void fillRange(int start, int end, [E? fill]) {
    super.fillRange(start, end, fill == null ? null : _promote(fill));
  }

  @override
  void insert(int index, E element) {
    super.insert(index, _promote(element));
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    super.insertAll(index, iterable.map(_promote));
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    super.replaceRange(start, end, newContents.map(_promote));
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    super.setAll(index, iterable.map(_promote));
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    super.setRange(start, end, iterable.map(_promote), skipCount);
  }
}

class CachedTypedDataList<T extends E, E> extends DelegatingList<T>
    with TypedDataListToString
    implements TypedDataList<T, E> {
  CachedTypedDataList(
    this._base, {
    required bool growable,
  })  : _cache = List.filled(_base.length, null, growable: growable),
        super(_base);

  final _TypedDataListBase<T, E, Array> _base;
  final List<T?> _cache;

  @override
  Object get internal => _base.internal;

  T _promote(E value) => _base._converter.promote(value);

  @override
  T operator [](int index) {
    final cachedValue = _cache[index];
    if (cachedValue != null) {
      return cachedValue;
    }

    final value = this[index];
    if (value != null) {
      // We must not store null in the cache, because we use it to detect if
      // a value has been cached or not.
      _cache[index] = value;
    }
    return value;
  }

  @override
  set length(int newLength) {
    super.length = newLength;
    _cache.length = newLength;
  }

  @override
  void operator []=(int index, E value) {
    final promoted = _promote(value);
    super[index] = promoted;
    _cache[index] = promoted;
  }

  @override
  void add(E value) {
    final promoted = _promote(value);
    super.add(promoted);
    _cache.add(promoted);
  }

  @override
  void addAll(Iterable<E> iterable) {
    final promoted = iterable.map(_promote).toList();
    super.addAll(promoted);
    _cache.addAll(promoted);
  }

  @override
  void fillRange(int start, int end, [E? fillValue]) {
    super.fillRange(start, end, fillValue == null ? null : _promote(fillValue));
  }

  @override
  void insert(int index, E element) {
    super.insert(index, _promote(element));
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    super.insertAll(index, iterable.map(_promote));
  }

  @override
  void replaceRange(int start, int end, Iterable<E> iterable) {
    super.replaceRange(start, end, iterable.map(_promote));
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    super.setAll(index, iterable.map(_promote));
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    super.setRange(start, end, iterable.map(_promote), skipCount);
  }
}

mixin TypedDataListToString<T> on List<T> {
  @override
  String toString({String? indent}) {
    if (indent == null) {
      return super.toString();
    } else {
      final buffer = StringBuffer()..writeln('[');
      for (final entry in this) {
        final lines = entry.renderStringIndented(indent);

        buffer
          ..write(indent)
          ..write(lines[0]);
        for (final line in lines.skip(1)) {
          buffer
            ..writeln()
            ..write(indent)
            ..write(line);
        }
        buffer.writeln(',');
      }
      buffer.write(']');
      return buffer.toString();
    }
  }
}

// === Typed data model ========================================================

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
  void checkDocumentIsOfType<D extends TypedDocumentObject>(Document doc) {
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
