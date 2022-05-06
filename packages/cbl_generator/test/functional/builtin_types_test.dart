import 'dart:typed_data';

import 'package:cbl/cbl.dart';
import 'package:test/test.dart';

import '../fixtures/builtin_types.dart';
import '../test_utils.dart';

void main() {
  setUpAll(initCouchbaseLiteForTest);

  test('create instance with value and retrieve it', () {
    expect(StringDict('a').value, 'a');
    expect(StringDoc('a').value, 'a');
    expect(IntDict(42).value, 42);
    expect(IntDoc(42).value, 42);
    expect(DoubleDict(.5).value, .5);
    expect(DoubleDoc(.5).value, .5);
    expect(NumDict(42).value, 42);
    expect(NumDoc(42).value, 42);
    expect(NumDict(.5).value, .5);
    expect(NumDoc(.5).value, .5);
    expect(BoolDict(true).value, true);
    expect(BoolDoc(true).value, true);
    expect(DateTimeDict(DateTime(2022)).value, DateTime(2022));
    expect(DateTimeDoc(DateTime(2022)).value, DateTime(2022));
    final blob = Blob.fromData('', Uint8List.fromList([42]));
    expect(BlobDict(blob).value, blob);
    expect(BlobDoc(blob).value, blob);
    expect(EnumDict(TestEnum.a).value, TestEnum.a);
    expect(EnumDoc(TestEnum.a).value, TestEnum.a);
  });
}
