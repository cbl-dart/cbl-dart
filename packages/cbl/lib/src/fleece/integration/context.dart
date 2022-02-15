import '../shared_strings.dart';

class MContext {
  MContext({
    SharedStrings? sharedStrings,
  }) : sharedStrings = sharedStrings ?? SharedStrings();

  final SharedStrings sharedStrings;
}
