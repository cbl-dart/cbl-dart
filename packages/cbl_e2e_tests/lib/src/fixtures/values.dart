import 'package:cbl/src/document/blob.dart';

final testBlob = BlobImpl.fromProperties({
  '@type': 'blob',
  'content_type': 'application/octet-stream',
  'length': 0,
  'digest': 'sha1-2jmj7l5rSw0yVb/vlWAYkK/YBwk=',
});

final testDate = DateTime.now();
