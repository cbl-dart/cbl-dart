import 'package:cbl/src/document/blob.dart';

final testBlob = BlobImpl.fromProperties({
  '@type': 'blob',
  'content_type': 'application/octet-stream',
  'length': 0,
  'digest': 'sha1-2jmj7l5rSw0yVb/vlWAYkK/YBwk=',
});

final testDate = DateTime.now();

/// The largest integer that Couchbase Lite can store.
final maxUint64 = (BigInt.one << 64) - BigInt.one;

/// The smallest integer that Couchbase Lite can store.
final minInt64 = -(BigInt.one << 63);

/// The largest value of an [int].
const maxInt64 = 9223372036854775807;
