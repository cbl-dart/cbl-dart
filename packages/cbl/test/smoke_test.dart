import 'dart:ffi';

import 'package:cbl/src/bindings/cblite.dart';
import 'package:cbl/src/bindings/cblitedart.dart';
import 'package:test/test.dart';

void main() {
  test('smoke', () {
    CBL_Retain(nullptr);
    CBLDart_CBLLog_SetCallback(nullptr);
  });
}
