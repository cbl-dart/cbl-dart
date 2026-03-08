import 'package:cbl/cbl.dart';

/// Whether vector search has been enabled.
///
/// Use this as a `skip` condition for tests that require vector search.
bool get vectorSearchEnabled =>
    Extension.vectorSearchStatus == VectorSearchStatus.enabled;
