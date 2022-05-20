import 'package:build_test/build_test.dart';
import 'package:cbl_generator/src/builder.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  test('annotated element is not a class', () async {
    await _expectBadSource(
      '''
@TypedDictionary()
const a = '';
  ''',
      '@TypedDictionary can only be used on a class.',
    );
  });

  test('class is not abstract', () async {
    await _expectBadSource(
      r'''
@TypedDictionary()
class A with _$A {
  factory A() = MutableA;
}
  ''',
      '@TypedDictionary can only be used on an abstract class.',
    );
  });

  test('class is not mixing in interface mixin', () async {
    await _expectBadSource(
      '''
@TypedDictionary()
abstract class A {
  factory A() = MutableA;
}
  ''',
      r'Class must mix in _$A.',
    );

    await _expectBadSource(
      r'''
@TypedDictionary()
abstract class A with _$B {
  factory A() = MutableA;
}
  ''',
      r'Class must mix in _$A.',
    );
  });

  test('class is not declaring redirecting unnamed constructor', () async {
    await _expectBadSource(
      r'''
@TypedDictionary()
abstract class A with _$A {
}
  ''',
      'Class must have a factory unnamed constructor which redirects to '
          'MutableA.',
    );

    await _expectBadSource(
      r'''
@TypedDictionary()
abstract class A with _$A {
  factory A() = MutableB;
}
  ''',
      'Class must have a factory unnamed constructor which redirects to '
          'MutableA.',
    );
  });

  test('class without fields', () async {
    await testBuilder(
      TypedDataBuilder(),
      {
        _testLibId: _testLibContent(r'''
@TypedDictionary()
abstract class A with _$A {
  factory A() = MutableA;
}
''')
      },
      outputs: {
        _genPartId: _typedDictionaryGeneratorContent(r'''
mixin _$A implements TypedDictionaryObject<MutableA> {}

abstract class _AImplBase<I extends Dictionary> with _$A implements A {
  _AImplBase(this.internal);

  @override
  final I internal;

  @override
  MutableA toMutable() => MutableA.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'A',
        fields: {},
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableA extends _AImplBase {
  ImmutableA.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is A &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [A].
class MutableA extends _AImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<A, MutableA> {
  /// Creates a new mutable [A].
  MutableA() : super(MutableDictionary());

  MutableA.internal(super.internal);
}
''')
      },
      reader: await PackageAssetReader.currentIsolate(),
    );
  });

  test('class with field with unsupported type', () async {
    await _expectBadSource(r'''
@TypedDictionary()
abstract class A with _$A {
  factory A(Uri b) = MutableA;
}
''', 'Unsupported type: Uri');
  });

  test('class with String field', () async {
    await testBuilder(
      TypedDataBuilder(),
      {
        _testLibId: _testLibContent(r'''
@TypedDictionary()
abstract class A with _$A {
  factory A(String b) = MutableA;
}
''')
      },
      outputs: {
        _genPartId: _typedDictionaryGeneratorContent(r'''
mixin _$A implements TypedDictionaryObject<MutableA> {
  String get b;
}

abstract class _AImplBase<I extends Dictionary> with _$A implements A {
  _AImplBase(this.internal);

  @override
  final I internal;

  @override
  String get b => TypedDataHelpers.readProperty(
        internal: internal,
        name: 'b',
        key: 'b',
        converter: TypedDataHelpers.stringConverter,
      );

  @override
  MutableA toMutable() => MutableA.internal(internal.toMutable());

  @override
  String toString({String? indent}) => TypedDataHelpers.renderString(
        indent: indent,
        className: 'A',
        fields: {
          'b': b,
        },
      );
}

/// DO NOT USE: Internal implementation detail, which might be changed or
/// removed in the future.
class ImmutableA extends _AImplBase {
  ImmutableA.internal(super.internal);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is A &&
          runtimeType == other.runtimeType &&
          internal == other.internal;

  @override
  int get hashCode => internal.hashCode;
}

/// Mutable version of [A].
class MutableA extends _AImplBase<MutableDictionary>
    implements TypedMutableDictionaryObject<A, MutableA> {
  /// Creates a new mutable [A].
  MutableA(
    String b,
  ) : super(MutableDictionary()) {
    this.b = b;
  }

  MutableA.internal(super.internal);

  set b(String value) {
    final promoted = TypedDataHelpers.stringConverter.promote(value);
    TypedDataHelpers.writeProperty(
      internal: internal,
      key: 'b',
      value: promoted,
      converter: TypedDataHelpers.stringConverter,
    );
  }
}
''')
      },
      reader: await PackageAssetReader.currentIsolate(),
    );
  });

  group('document', () {
    test('conflicting field names from getters and constructor parameters',
        () async {
      await _expectBadSource(
          r'''
@TypedDocument()
abstract class A with _$A {
  factory A(String a, String b, String c) = MutableA;

  @DocumentId()
  String get a;

  @DocumentSequence()
  int get b;
}
''',
          'Getters annotated with @DocumentId, @DocumentSequence, or '
              '@DocumentRevisionId are conflicting with constructor '
              'parameters: a, b');
    });

    group('DocumentId', () {
      test('unsupported field type', () async {
        await _expectBadSource(r'''
@TypedDocument()
abstract class A with _$A {
  factory A(@DocumentId() int id) = MutableA;
}
''', '@DocumentId must be used on a String field.');
      });

      test('used on a dictionary', () async {
        await _expectBadSource(
          r'''
@TypedDictionary()
abstract class A with _$A {
  factory A(@DocumentId() String id) = MutableA;
}
''',
          '@DocumentId cannot be used in a dictionary, and only in a document.',
        );
      });

      test('used in constructor and on getter', () async {
        await _expectBadSource(
          r'''
@TypedDocument()
abstract class A with _$A {
  factory A(@DocumentId() String id) = MutableA;

  @DocumentId()
  String get id;
}
''',
          '@DocumentId cannot both be used on a constructor parameter and a '
              'getter, within the same class.',
        );
      });

      test('used on getter with incorrect type', () async {
        await _expectBadSource(
          r'''
@TypedDocument()
abstract class A with _$A {
  factory A() = MutableA;

  @DocumentId()
  int get id;
}
''',
          '@DocumentId must be used on a getter which returns a String.',
        );
      });
    });

    group('DocumentSequence', () {
      test('used on getter with incorrect type', () async {
        await _expectBadSource(
          r'''
@TypedDocument()
abstract class A with _$A {
  factory A() = MutableA;

  @DocumentSequence()
  String get sequence;
}
''',
          '@DocumentSequence must be used on a getter which returns a int.',
        );
      });
    });

    group('DocumentRevisionId', () {
      test('used on getter with incorrect type', () async {
        await _expectBadSource(
          r'''
@TypedDocument()
abstract class A with _$A {
  factory A() = MutableA;

  @DocumentRevisionId()
  String get sequence;
}
''',
          '@DocumentRevisionId must be used on a getter which returns a '
              'String?.',
        );
      });
    });
  });
}

const _testPkg = 'pkg';
const _testLib = 'lib';
const _testLibFileName = '$_testLib.dart';
const _genPartFileName = '$_testLib.cbl.type.g.dart';
const _testLibId = '$_testPkg|$_testLibFileName';
const _genPartId = '$_testPkg|$_genPartFileName';

String _testLibContent(String content) => '''
import 'package:cbl/cbl.dart';

part '$_genPartFileName';

$content''';

final _genPartHeader = '''
${TypedDataBuilder.header}
part of '$_testLibFileName';''';

String _typedDictionaryGeneratorContent(String content) => '''
$_genPartHeader

// **************************************************************************
// TypedDictionaryGenerator
// **************************************************************************

$content''';

Future<void> _expectBadSource(String source, [Object? messageMatcher]) async {
  await expectLater(
    testBuilder(
      TypedDataBuilder(),
      {_testLibId: _testLibContent(source)},
      reader: await PackageAssetReader.currentIsolate(),
    ),
    throwsA(isA<InvalidGenerationSourceError>().having(
      (error) => error.message,
      'message',
      messageMatcher ?? anything,
    )),
  );
}
