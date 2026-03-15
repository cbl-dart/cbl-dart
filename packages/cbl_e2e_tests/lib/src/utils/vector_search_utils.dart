import 'package:cbl/cbl.dart';

/// Whether vector search is available or has been enabled.
///
/// Use this as a `skip` condition for tests that require vector search. This
/// checks for both [VectorSearchStatus.available] and
/// [VectorSearchStatus.enabled] so that it works at test registration time
/// (before [Extension.enableVectorSearch] is called in `setUpAll`).
bool get vectorSearchAvailable => switch (Extension.vectorSearchStatus) {
  VectorSearchStatus.available || VectorSearchStatus.enabled => true,
  _ => false,
};
