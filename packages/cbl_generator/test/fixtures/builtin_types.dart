// ignore_for_file: avoid_positional_boolean_parameters

import 'package:cbl/cbl.dart';

part 'builtin_types.cbl.type.g.dart';

@TypedDictionary()
abstract class StringDict with _$StringDict {
  factory StringDict(String value) = MutableStringDict;
}

@TypedDocument()
abstract class StringDoc with _$StringDoc {
  factory StringDoc(String value) = MutableStringDoc;
}

@TypedDictionary()
abstract class IntDict with _$IntDict {
  factory IntDict(int value) = MutableIntDict;
}

@TypedDocument()
abstract class IntDoc with _$IntDoc {
  factory IntDoc(int value) = MutableIntDoc;
}

@TypedDictionary()
abstract class DoubleDict with _$DoubleDict {
  factory DoubleDict(double value) = MutableDoubleDict;
}

@TypedDocument()
abstract class DoubleDoc with _$DoubleDoc {
  factory DoubleDoc(double value) = MutableDoubleDoc;
}

@TypedDictionary()
abstract class NumDict with _$NumDict {
  factory NumDict(num value) = MutableNumDict;
}

@TypedDocument()
abstract class NumDoc with _$NumDoc {
  factory NumDoc(num value) = MutableNumDoc;
}

@TypedDictionary()
abstract class BoolDict with _$BoolDict {
  factory BoolDict(bool value) = MutableBoolDict;
}

@TypedDocument()
abstract class BoolDoc with _$BoolDoc {
  factory BoolDoc(bool value) = MutableBoolDoc;
}

@TypedDictionary()
abstract class DateTimeDict with _$DateTimeDict {
  factory DateTimeDict(DateTime value) = MutableDateTimeDict;
}

@TypedDocument()
abstract class DateTimeDoc with _$DateTimeDoc {
  factory DateTimeDoc(DateTime value) = MutableDateTimeDoc;
}

@TypedDictionary()
abstract class BlobDict with _$BlobDict {
  factory BlobDict(Blob value) = MutableBlobDict;
}

@TypedDocument()
abstract class BlobDoc with _$BlobDoc {
  factory BlobDoc(Blob value) = MutableBlobDoc;
}

@TypedDictionary()
abstract class NullableIntDict with _$NullableIntDict {
  factory NullableIntDict(int? value) = MutableNullableIntDict;
}

@TypedDictionary()
abstract class NullableDoubleDict with _$NullableDoubleDict {
  factory NullableDoubleDict(double? value) = MutableNullableDoubleDict;
}

@TypedDictionary()
abstract class NullableNumDict with _$NullableNumDict {
  factory NullableNumDict(num? value) = MutableNullableNumDict;
}

@TypedDictionary()
abstract class NullableBoolDict with _$NullableBoolDict {
  factory NullableBoolDict(bool? value) = MutableNullableBoolDict;
}

enum TestEnum { a }

@TypedDictionary()
abstract class EnumDict with _$EnumDict {
  factory EnumDict(TestEnum value) = MutableEnumDict;
}

@TypedDocument()
abstract class EnumDoc with _$EnumDoc {
  factory EnumDoc(TestEnum value) = MutableEnumDoc;
}
