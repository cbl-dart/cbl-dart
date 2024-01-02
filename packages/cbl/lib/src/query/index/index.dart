import '../../bindings.dart';
import '../../database.dart';
import '../query.dart';

/// A description of a [Database] index. Indexes improve [Query] performance.
///
/// {@category Query}
abstract class Index {}

/// A language which can be used to configure as the primary language for a full
/// text index.
///
/// {@category Query}
enum FullTextLanguage {
  danish,
  dutch,
  english,
  finnish,
  french,
  german,
  hungarian,
  italian,
  norwegian,
  portuguese,
  romanian,
  russian,
  spanish,
  swedish,
  turkish,
}

// === Impl ====================================================================

/// Interface for classes wich implement [Index].
abstract class IndexImplInterface extends Index {
  /// Returns this index specified as a [CBLIndexSpec].
  CBLIndexSpec toCBLIndexSpec();
}
