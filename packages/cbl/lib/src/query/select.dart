import '../query.dart';
import 'data_source.dart';
import 'from.dart';
import 'query.dart';
import 'router/from_router.dart';
import 'select_result.dart';

/// A query component representing the `SELECT` clause of a [Query].
abstract class Select implements Query, FromRouter {}

// === Impl ====================================================================

class SelectImpl extends BuilderQuery implements Select {
  SelectImpl(Iterable<SelectResultInterface> select, bool distinct)
      : super(selects: select, distinct: distinct);

  @override
  From from(DataSourceInterface dataSource) =>
      FromImpl(query: this, from: dataSource);
}
