import 'package:cbl_ffi/cbl_ffi.dart';

import '../../database.dart';
import '../query.dart';

/// A description of a [Database] index. Indexes improve [Query] performance.
abstract class Index {}

/// Interface for classes wich implement [Index].
abstract class IndexImplInterface extends Index {
  /// Returns this index specified as a [CBLIndexSpec].
  CBLIndexSpec toCBLIndexSpec();
}
