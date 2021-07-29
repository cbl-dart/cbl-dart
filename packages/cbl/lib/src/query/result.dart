import 'package:cbl/src/document/array.dart';
import 'package:cbl/src/document/dictionary.dart';

abstract class Result
    implements ArrayInterface, DictionaryInterface, Iterable<String> {}
