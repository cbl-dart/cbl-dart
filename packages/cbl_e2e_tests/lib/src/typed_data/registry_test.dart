// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:cbl/cbl.dart';
import 'package:cbl/src/typed_data/registry.dart';

import '../../test_binding_impl.dart';
import '../test_binding.dart' hide TypeMatcher;
import '../utils/matchers.dart';

void main() {
  setupTestBinding();

  group('ValueTypeMatcherImpl', () {
    group('isMatch', () {
      test('root dictionary', () {
        expectTypeMatches(
          ValueTypeMatcherImpl(path: ['a'], value: 'v'),
          matches: [
            {'a': 'v'}
          ],
          matchesNot: [
            {'a': 'x'},
            {}
          ],
        );
      });

      test('nested dictionary', () {
        expectTypeMatches(
          ValueTypeMatcherImpl(path: ['a', 'b'], value: 'v'),
          matches: [
            {
              'a': {'b': 'v'}
            }
          ],
          matchesNot: [
            {
              'a': {'b': 'x'}
            },
            {'a': <String, Object?>{}},
            {'a': <Object?>[]},
            {}
          ],
        );
        expectTypeMatches(
          ValueTypeMatcherImpl(path: ['a', 0, 'b'], value: 'v'),
          matches: [
            {
              'a': [
                {'b': 'v'}
              ]
            }
          ],
          matchesNot: [
            {
              'a': [
                {'b': 'x'}
              ]
            },
            {
              'a': [<String, Object?>{}]
            },
            {
              'a': [<Object?>[]]
            },
            {'a': <Object?>[]},
            {}
          ],
        );
      });

      test('nested array', () {
        expectTypeMatches(
          ValueTypeMatcherImpl(path: ['a', 0], value: 'v'),
          matches: [
            {
              'a': ['v']
            }
          ],
          matchesNot: [
            {
              'a': ['x']
            },
            {'a': <String, Object?>{}},
            {'a': <Object?>[]},
            {}
          ],
        );
        expectTypeMatches(
          ValueTypeMatcherImpl(path: ['a', 'b', 0], value: 'v'),
          matches: [
            {
              'a': {
                'b': ['v']
              }
            }
          ],
          matchesNot: [
            {
              'a': {
                'b': ['x']
              }
            },
            {
              'a': {'b': <String, Object?>{}}
            },
            {
              'a': {'b': <Object?>[]}
            },
            {'a': <String, Object?>{}},
            {}
          ],
        );
      });
    });

    group('makeMatch', () {
      test('root dictionary', () {
        expectMakesMatch(
          ValueTypeMatcherImpl(path: ['a'], value: 'v'),
          validStates: [
            {},
            {'a': 'v'},
          ],
          invalidStates: [
            {'a': null},
            {'a': 'x'},
            {'a': <Object?>[]},
            {'a': <String, Object?>{}},
          ],
        );
      });

      test('nested dictionary', () {
        expectMakesMatch(
          ValueTypeMatcherImpl(path: ['a', 'b'], value: 'v'),
          validStates: [
            {'a': <String, Object?>{}},
            {
              'a': {'b': 'v'}
            },
          ],
          invalidStates: [
            {'a': null},
            {'a': <Object?>[]},
            {
              'a': {'b': 'x'}
            },
            {
              'a': {'b': <Object?>[]}
            },
            {
              'a': {'b': <String, Object?>{}}
            },
          ],
        );
        expectMakesMatch(
          ValueTypeMatcherImpl(path: ['a', 0, 'b'], value: 'v'),
          validStates: [
            {
              'a': [<String, Object?>{}]
            },
            {
              'a': [
                {'b': 'v'}
              ]
            },
          ],
          invalidStates: [
            {
              'a': [null]
            },
            {
              'a': [<Object?>[]]
            },
            {
              'a': [
                {'b': 'x'}
              ]
            },
            {
              'a': [
                {'b': <Object?>[]}
              ]
            },
            {
              'a': [
                {'b': <String, Object?>{}}
              ]
            },
          ],
        );
      });

      test('nested array', () {
        expectMakesMatch(
          ValueTypeMatcherImpl(path: ['a', 0], value: 'v'),
          validStates: [
            {'a': <Object?>[]},
            {
              'a': ['v']
            },
          ],
          invalidStates: [
            {'a': null},
            {'a': <String, Object?>{}},
            {
              'a': ['x']
            },
            {
              'a': [<Object?>[]]
            },
            {
              'a': [<String, Object?>{}]
            },
          ],
        );
        expectMakesMatch(
          ValueTypeMatcherImpl(path: ['a', 1], value: 'v'),
          validStates: [
            {
              'a': [null]
            },
            {
              'a': [null, 'v']
            },
          ],
          invalidStates: [
            {'a': null},
            {'a': <String, Object?>{}},
            {'a': <Object?>[]},
            {
              'a': [null, 'x']
            },
            {
              'a': [null, <Object?>[]]
            },
            {
              'a': [null, <String, Object?>{}]
            },
          ],
        );
        expectMakesMatch(
          ValueTypeMatcherImpl(path: ['a', 'b', 0], value: 'v'),
          validStates: [
            {
              'a': {'b': <Object?>[]}
            },
            {
              'a': {
                'b': ['v']
              }
            },
          ],
          invalidStates: [
            {'a': null},
            {'a': <String, Object?>{}},
            {
              'a': {'b': null}
            },
            {
              'a': {'b': <String, Object?>{}}
            },
            {
              'a': {
                'b': ['x']
              }
            },
            {
              'a': {
                'b': [<Object?>[]]
              }
            },
            {
              'a': {
                'b': [<String, Object?>{}]
              }
            },
          ],
        );
      });
    });
  });
}

void expectTypeMatches(
  TypeMatcherImpl typeMatcher, {
  required List<Map<String, Object?>> matches,
  required List<Map<String, Object?>> matchesNot,
}) {
  for (final value in matches) {
    expect(typeMatcher, matchesValue(MutableDictionary(value)));
  }
  for (final value in matchesNot) {
    expect(typeMatcher, isNot(matchesValue(MutableDictionary(value))));
  }
}

Matcher matchesValue(DictionaryInterface value) => _MatchesValue(value);

class _MatchesValue extends Matcher {
  _MatchesValue(this.value);

  final DictionaryInterface value;

  @override
  Description describe(Description description) => description
      .add('type matcher matches ')
      .addDescriptionOf(value.toPlainMap());

  @override
  bool matches(covariant TypeMatcherImpl item, Map matchState) =>
      item.isMatch(value);

  @override
  Description describeMismatch(
    covariant TypeMatcherImpl item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) =>
      mismatchDescription.addDescriptionOf(item).add(' does not match value');
}

void expectMakesMatch(
  TypeMatcherImpl typeMatcher, {
  required List<Map<String, Object?>> validStates,
  required List<Map<String, Object?>> invalidStates,
}) {
  for (final value in validStates) {
    final dict = MutableDictionary(value);
    expect(
      () => typeMatcher.makeMatch(dict),
      returnsNormally,
      reason: 'makeMatch should not throw for $value',
    );
    expect(typeMatcher, matchesValue(dict));
  }

  for (final value in invalidStates) {
    final dict = MutableDictionary(value);
    expect(
      () => typeMatcher.makeMatch(dict),
      throwsA(isTypedDataException.havingCode(TypedDataErrorCode.dataMismatch)),
      reason: 'makeMatch should throw for $value',
    );
  }
}
