import 'package:test/test.dart';

import '../fixtures/constructor_parameters.dart';
import '../test_utils.dart';

void main() {
  setUpAll(initCouchbaseLiteForTest);

  test('initialize properties fields', () {
    expect(MutableParamDict('a').a, 'a');
    expect(MutableParamDoc('a').a, 'a');
    expect(MutableOptionalParamDict('a').a, 'a');
    expect(MutableOptionalParamDoc('a').a, 'a');
    expect(MutableOptionalParamDict().a, isNull);
    expect(MutableOptionalParamDoc().a, isNull);
    final mutablePositionalMixedParamDict =
        MutablePositionalMixedParamDict('a', 'b');
    expect(mutablePositionalMixedParamDict.a, 'a');
    expect(mutablePositionalMixedParamDict.b, 'b');
    final mutablePositionalMixedParamDoc =
        MutablePositionalMixedParamDoc('a', 'b');
    expect(mutablePositionalMixedParamDoc.a, 'a');
    expect(mutablePositionalMixedParamDoc.b, 'b');
    expect(MutableNamedParamDict(a: 'a').a, 'a');
    expect(MutableNamedParamDoc(a: 'a').a, 'a');
    expect(MutableNamedOptionalParamDict(a: 'a').a, 'a');
    expect(MutableNamedOptionalParamDoc(a: 'a').a, 'a');
    expect(MutableNamedOptionalParamDict().a, isNull);
    expect(MutableNamedOptionalParamDoc().a, isNull);
    final mutableNamedMixedParamDict = MutableNamedMixedParamDict('a', b: 'b');
    expect(mutableNamedMixedParamDict.a, 'a');
    expect(mutableNamedMixedParamDict.b, 'b');
    final mutableNamedMixedParamDoc = MutableNamedMixedParamDoc('a', b: 'b');
    expect(mutableNamedMixedParamDoc.a, 'a');
    expect(mutableNamedMixedParamDoc.b, 'b');
  });
}
