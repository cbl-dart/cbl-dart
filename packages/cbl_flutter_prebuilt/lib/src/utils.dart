typedef JsonMap = Map<String, Object?>;

extension EnumExt on Enum {
  String get name => toString().split('.')[1];
}
