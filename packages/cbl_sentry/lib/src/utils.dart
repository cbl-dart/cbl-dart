// coverage:ignore-start
Never unreachable() {
  throw Exception('This code should not be reached');
}
// coverage:ignore-end

extension StringExt on String {
  String get uncapitalized =>
      isEmpty ? this : substring(0, 1).toLowerCase() + substring(1);
}
