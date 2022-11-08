import 'package:logging/logging.dart';

final logger = Logger.detached('cbl_dart');

extension EnumNameExt on Enum {
  String get name => toString().split('.').last;
}
