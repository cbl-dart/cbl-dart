/// Collation defines how strings are compared and is used when creating a
/// `COLLATE` expression.
///
/// The `COLLATE` expression can be used in the `WHERE` clause when comparing
/// two string or in the `ORDER BY` clause when specifying how the order of the
/// query results.
///
/// {@category Query Builder}
abstract class CollationInterface {}

/// Factory for creating collations.
///
/// Couchbase Lite provides two types of collation: ASCII and Unicode. Without
/// specifying the `COLLATE` expression Couchbase Lite will use case sensitive
/// ASCII collation.
///
/// {@category Query Builder}
class Collation {
  Collation._();

  /// Creates an ASCII collation that will compare strings by using binary
  /// comparison.
  static AsciiCollation ascii() => AsciiCollationImpl();

  /// Creates an Unicode collation that will compare strings by using the
  /// Unicode collation algorithm.
  ///
  /// If the locale is not specified, the collation is Unicode-aware but not
  /// localized; for example, accented Roman letters sort right after the base
  /// letter (This is implemented by using the "en_US" locale.).
  static UnicodeCollation unicode() => UnicodeCollationImpl();
}

/// ASCII collation compares two string by using binary comparison.
///
/// {@category Query Builder}
abstract class AsciiCollation extends CollationInterface {
  /// Specifies whether the collation is case-sensitive or not.
  ///
  /// Case-sensitive collation will treat ASCII uppercase and lowercase letters
  /// as equivalent.
  // ignore: avoid_positional_boolean_parameters
  AsciiCollation ignoreCase(bool ignoreCase);
}

/// [Unicode Collation](https://unicode-org.github.io/icu/userguide/collation/)
/// that will compare two strings by using the Unicode collation algorithm.
///
/// If the local is not specified, the collation is Unicode-aware but not
/// localized; for example, accented Roman letters sort right after the base
/// letter (This is implemented by using the "en_US" locale.).
///
/// {@category Query Builder}
abstract class UnicodeCollation extends CollationInterface {
  /// Specifies whether the collation is case-insensitive or not.
  ///
  /// Case-insensitive collation will treat uppercase and lowercase letters as
  /// equivalent.
  // ignore: avoid_positional_boolean_parameters
  UnicodeCollation ignoreCase(bool ignoreCase);

  /// Specifies whether the collation ignores accents and diacritics.
  // ignore: avoid_positional_boolean_parameters
  UnicodeCollation ignoreAccents(bool ignoreAccents);

  /// Specifies the [locale] for which the collation will compare strings
  /// appropriately based on the locale.
  ///
  /// The [locale] must be specified as an
  /// [ISO-639](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) language
  /// code plus, optionally, an underscore and an
  /// [ISO-3166](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes)
  /// country code, e.g: "en", "en_US", "fr_CA", etc.
  ///
  /// If not specified, the "en_US" locale will be used.
  UnicodeCollation locale(String? locale);
}

// === Impl ====================================================================

abstract class CollationImpl extends CollationInterface {
  Object? toJson();
}

class AsciiCollationImpl extends CollationImpl implements AsciiCollation {
  AsciiCollationImpl({bool ignoreCase = false}) : _ignoreCase = ignoreCase;

  final bool _ignoreCase;

  @override
  AsciiCollationImpl ignoreCase(bool ignoreCase) =>
      AsciiCollationImpl(ignoreCase: ignoreCase);

  @override
  Object? toJson() => {
        'UNICODE': false,
        'CASE': !_ignoreCase,
      };
}

class UnicodeCollationImpl extends CollationImpl implements UnicodeCollation {
  UnicodeCollationImpl({
    bool ignoreCase = false,
    bool ignoreAccents = false,
    String? locale,
  })  : _ignoreCase = ignoreCase,
        _ignoreAccents = ignoreAccents,
        _locale = locale;

  final bool _ignoreCase;
  final bool _ignoreAccents;
  final String? _locale;

  UnicodeCollation copyWith({
    bool? ignoreCase,
    bool? ignoreAccents,
    String? locale,
  }) =>
      UnicodeCollationImpl(
        ignoreCase: ignoreCase ?? _ignoreCase,
        ignoreAccents: ignoreAccents ?? _ignoreAccents,
        locale: locale ?? _locale,
      );

  @override
  UnicodeCollation ignoreCase(bool ignoreCase) =>
      copyWith(ignoreCase: ignoreCase);

  @override
  UnicodeCollation ignoreAccents(bool ignoreAccents) =>
      copyWith(ignoreAccents: ignoreAccents);

  @override
  UnicodeCollation locale(String? locale) => copyWith(locale: locale);

  @override
  Object? toJson() => {
        'UNICODE': true,
        'CASE': !_ignoreCase,
        'DIAC': !_ignoreAccents,
        'LOCALE': _locale,
      };
}
