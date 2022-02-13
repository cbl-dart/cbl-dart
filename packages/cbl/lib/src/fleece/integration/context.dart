import '../decoder.dart';

class MContext {
  MContext({
    SharedStrings? sharedStrings,
  }) : sharedStrings = sharedStrings ?? SharedStrings();

  final SharedStrings sharedStrings;
}
