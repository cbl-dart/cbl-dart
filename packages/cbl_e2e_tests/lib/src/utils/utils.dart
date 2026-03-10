import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;

/// Returns a skip reason when replication tests should be skipped on the
/// current platform, or `null` if they should run.
String? get skipReplicationTests => Platform.isLinux || Platform.isAndroid
    ? 'Version vector clock issues on Linux and Android'
    : null;

// TODO: Fix peer-to-peer tests on macOS + Flutter + CI and iOS.
// On iOS, the listener URLs use the machine's hostname which can't be resolved
// from the iOS simulator.
// ignore: do_not_use_environment
const _skipPeerSyncTestEnv = bool.fromEnvironment('skipPeerSyncTest');

/// Returns a skip reason when peer sync tests should be skipped on the current
/// platform, or `null` if they should run.
final String? skipPeerSyncTest = _skipPeerSyncTestEnv
    ? 'Skipping test on macOS + Flutter + CI'
    : Platform.isIOS
    ? 'Listener URLs use machine hostname, unresolvable on iOS simulator'
    : Platform.isLinux
    ? 'TLS/crypto issues on Linux (see #882)'
    : null;

String md5OfString(String input) => crypto.md5
    .convert(utf8.encode(input))
    .bytes
    .map((e) => e.toRadixString(16).padLeft(2, '0'))
    .join();
