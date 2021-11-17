import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

String md5OfString(String input) => crypto.md5
    .convert(utf8.encode(input))
    .bytes
    .map((e) => e.toRadixString(16).padLeft(2, '0'))
    .join();
