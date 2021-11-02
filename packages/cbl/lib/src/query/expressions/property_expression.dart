import 'expression.dart';

/// A property expression.
///
/// {@category Query Builder}
abstract class PropertyExpressionInterface extends ExpressionInterface {
  /// Specifies the [alias] of the data source to query the data from.
  ExpressionInterface from(String alias);
}

// === Impl ====================================================================

class PropertyExpressionImpl extends ExpressionImpl
    implements PropertyExpressionInterface {
  PropertyExpressionImpl(String propertyPath, {String? from})
      : _propertyPath = propertyPath,
        _from = from;

  PropertyExpressionImpl.all() : this('');

  final String _propertyPath;
  final String? _from;

  @override
  ExpressionInterface from(String alias) =>
      PropertyExpressionImpl(_propertyPath, from: alias);

  @override
  Object? toJson() =>
      [if (_from == null) '.$_propertyPath' else '.$_from.$_propertyPath'];
}
