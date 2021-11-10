extension EnumNameExt on Enum {
  String get name => toString().split('.').last;
}
