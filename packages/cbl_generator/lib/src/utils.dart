extension StringExt on String {
  String get decapitalized =>
      isEmpty ? this : replaceRange(0, 1, this[0].toLowerCase());
}
