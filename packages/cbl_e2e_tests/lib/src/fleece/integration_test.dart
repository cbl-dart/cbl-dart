// ignore_for_file: cast_nullable_to_non_nullable

import 'dart:ffi';

import 'package:cbl/src/bindings.dart';
import 'package:cbl/src/fleece/containers.dart';
import 'package:cbl/src/fleece/integration/integration.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart';
import '../utils/fleece_coding.dart';
import '../utils/matchers.dart';

final _arrayBinds = CBLBindings.instance.fleece.array;
final _dictBinds = CBLBindings.instance.fleece.dict;

void main() {
  setupTestBinding();

  group('Fleece Integration', () {
    // The previous delegate needs to be restored because
    // `CouchbaseLite.init called once for all tests, which is
    // where the MDelegate implementation for CouchbaseList is set up.
    MDelegate? previousDelegate;

    setUpAll(() {
      previousDelegate = MDelegate.instance;
      MDelegate.instance = SimpleMDelegate();
    });

    tearDownAll(() {
      MDelegate.instance = previousDelegate;
    });

    group('MArray', () {
      test('length of new array', () {
        final array = MArray();
        expect(array.length, 0);
        array.append(null);
        expect(array.length, 1);
        array.insert(0, null);
        expect(array.length, 2);
        array.remove(0);
        expect(array.length, 1);
        array.clear();
        expect(array.length, 0);
      });

      test('length of existing array', () {
        final root = testMRoot([null]);
        final array = root.asNative as MArray;
        expect(array.length, 1);
        array.append(null);
        expect(array.length, 2);
        array.insert(0, null);
        expect(array.length, 3);
        array.remove(0);
        expect(array.length, 2);
        array.clear();
        expect(array.length, 0);
      });

      test('get value from new array', () {
        final array = MArray();
        expect(array.get(0), isNull);
        array.append(null);
        expect(array.get(0), MValue.withNative(null));
        array.remove(0);
        expect(array.get(0), isNull);
      });

      test('get value from existing array', () {
        final root = testMRoot([null]);
        final array = root.asNative as MArray;
        final flArray = root.values.first.value!.cast<FLArray>();

        expect(array.get(0), MValue.withValue(_arrayBinds.get(flArray, 0)));
        array.remove(0);
        expect(array.get(0), isNull);
        array.append(null);
        expect(array.get(0), MValue.withNative(null));
      });

      test('set returns whether index was inbounds', () {
        final array = MArray();
        expect(array.set(0, null), false);
        array.append(null);
        expect(array.set(0, null), true);
      });

      test('insert returns whether index was inbounds', () {
        final array = MArray();
        expect(array.insert(1, null), false);
        expect(array.insert(0, null), true);
      });

      test('remove returns whether index was inbounds', () {
        final array = MArray();
        expect(array.remove(0), false);
        array.append(null);
        expect(array.remove(0), true);
      });

      test('set a value which shadows original value', () {
        final root = testMRoot([0, 1]);
        final array = root.asNative as MArray;
        final flArray = root.values.first.value!.cast<FLArray>();
        final value = array.get(0)!;

        expect(root.isMutated, isFalse);
        expect(array.isMutated, isFalse);
        expect(value.isMutated, isFalse);
        expect(value, MValue.withValue(_arrayBinds.get(flArray, 0)));

        array.set(0, 1);

        expect(root.isMutated, isTrue);
        expect(array.isMutated, isTrue);
        expect(value.isMutated, isTrue);
        expect(value, MValue.withNative(1));

        expect(root.encode(), json([1, 1]));
      });

      test('inserting in the middle after shadowing original value', () {
        final root = testMRoot([1, 2]);
        (root.asNative as MArray)
          ..set(0, null)
          ..insert(1, null);

        expect(root.encode(), json([null, null, 2]));
      });

      test('encodeTo non-mutated existing array ', () {
        final root = testMRoot([null]);
        expect(root.encode(), json([null]));
      });

      test('encodeTo mutated existing array ', () {
        final root = testMRoot([null]);
        (root.asNative as MArray)
          ..insert(0, true)
          ..append(false);
        expect(root.encode(), json([true, null, false]));
      });

      test('encodeTo new array ', () {
        final root = testMRoot([null]);
        (root.asNative as MArray).append(MArray()..append(true));

        expect(
          root.encode(),
          json([
            null,
            [true]
          ]),
        );
      });
    });

    group('MDict', () {
      test('length of new dict', () {
        final dict = MDict();
        expect(dict.length, 0);
        dict.set('a', null);
        expect(dict.length, 1);
        dict.remove('a');
        expect(dict.length, 0);
        dict.set('a', null);

        // ignore: cascade_invocations
        dict.clear();
        expect(dict.length, 0);
      });

      test('length of existing dict', () {
        final root = testMRoot({'x': null});
        final dict = root.asNative as MDict;
        expect(dict.length, 1);
        dict.set('a', null);
        expect(dict.length, 2);
        dict.remove('a');
        expect(dict.length, 1);
        dict.set('a', null);

        // ignore: cascade_invocations
        dict.clear();
        expect(dict.length, 0);
      });

      test('get value from new dict', () {
        final dict = MDict();
        expect(dict.get('a'), isNull);
        dict.set('a', null);
        expect(dict.get('a'), MValue.withNative(null));
        dict.remove('a');
        expect(dict.get('a'), isNull);
      });

      test('get value from existing dict', () {
        final root = testMRoot({'a': null});
        final dict = root.asNative as MDict;
        final flDict = root.values.first.value!.cast<FLDict>();

        expect(dict.get('a'), MValue.withValue(_dictBinds.get(flDict, 'a')!));
        dict.remove('a');
        expect(dict.get('a'), isNull);
        dict.set('a', null);
        expect(dict.get('a'), MValue.withNative(null));
      });

      test('set a value which shadows original value', () {
        final root = testMRoot({'a': true, 'b': true});
        final dict = root.asNative as MDict;
        final flDict = root.values.first.value!.cast<FLDict>();
        final value = dict.get('a');

        expect(root.isMutated, isFalse);
        expect(dict.isMutated, isFalse);
        expect(value!.isMutated, isFalse);
        expect(value, MValue.withValue(_dictBinds.get(flDict, 'a')!));

        dict.set('a', false);

        expect(root.isMutated, isTrue);
        expect(dict.isMutated, isTrue);
        expect(value.isMutated, isTrue);
        expect(value, MValue.withNative(false));

        expect(root.encode(), json({'a': false, 'b': true}));
      });

      test('encodeTo non-mutated existing dict ', () {
        final root = testMRoot({'a': null});
        expect(root.encode(), json({'a': null}));
      });

      test('encodeTo mutated existing dict ', () {
        final root = testMRoot({'a': null});
        (root.asNative as MDict).set('b', true);

        expect(root.encode(), json({'a': null, 'b': true}));
      });

      test('encodeTo new dict', () {
        final root = testMRoot({'a': null});
        (root.asNative as MDict).set('b', MDict()..set('c', true));

        expect(
          root.encode(),
          json({
            'a': null,
            'b': {'c': true}
          }),
        );
      });

      test('iterable for non-mutated dict', () {
        final root = testMRoot({'a': null});
        final dict = root.asNative as MDict;
        final flDict = root.values.first.value!.cast<FLDict>();

        expect(
          Map.fromEntries(dict.iterable),
          {'a': mValue(value: _dictBinds.get(flDict, 'a'))},
        );
      });

      test('iterable for mutated dict', () {
        final root = testMRoot({'a': null});
        final dict = root.asNative as MDict;
        final flDict = root.values.first.value!.cast<FLDict>();
        dict.set('b', true);

        expect(
          Map.fromEntries(dict.iterable),
          {
            'a': mValue(value: _dictBinds.get(flDict, 'a')),
            'b': mValue(hasNative: true),
          },
        );
      });
    });
  });
}

MRoot testMRoot(Object from) => MRoot.fromContext(
      MContext(data: Doc.fromResultData(fleeceEncode(from), FLTrust.trusted)),
      isMutable: true,
    );

Matcher mValue({Pointer<FLValue>? value, bool? hasNative}) => isA<MValue>()
    .having((p0) => p0.value, 'value', value ?? anything)
    .having((p0) => p0.hasNative, 'hasNative', hasNative ?? anything);
