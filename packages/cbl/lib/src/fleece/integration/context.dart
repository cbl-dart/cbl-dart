import '../dict_key.dart';
import '../shared_strings.dart';

class MContext {
  MContext({
    DictKeys? dictKeys,
    SharedStrings? sharedStrings,
  })  : dictKeys = dictKeys ?? UnoptimizingDictKeys(),
        sharedStrings = sharedStrings ?? SharedStrings();

  final DictKeys? dictKeys;
  final SharedStrings sharedStrings;
}
