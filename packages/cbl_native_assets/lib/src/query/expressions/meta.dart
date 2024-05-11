import 'expression.dart';
import 'property_expression.dart';

/// A document metadata expression.
///
/// {@category Query Builder}
abstract final class MetaExpressionInterface implements ExpressionInterface {
  /// Specifies the [alias] of the data source to query the metadata from.
  ExpressionInterface from(String alias);
}

// ignore: avoid_classes_with_only_static_members
/// Factory for creating expressions of metadata properties of a document.
///
/// {@category Query Builder}
abstract final class Meta {
  /// Creates a metadata expression referring to the id of a document.
  static MetaExpressionInterface get id => MetaExpressionImpl('_id');

  /// Creates a metadata expression referring to the revision id of a document.
  static MetaExpressionInterface get revisionId =>
      MetaExpressionImpl('_revisionID');

  /// Creates a metadata expression referring to the local sequence number of a
  /// document.
  ///
  /// The sequence number indicates how recently a document has been changed.
  /// The document that has changed more recently has a higher sequence number.
  static MetaExpressionInterface get sequence =>
      MetaExpressionImpl('_sequence');

  /// Creates a metadata expression referring to the deleted flag of a document.
  static MetaExpressionInterface get isDeleted =>
      MetaExpressionImpl('_deleted');

  /// Creates a metadata expression referring to the expiration timestamp of a
  /// document.
  static MetaExpressionInterface get expiration =>
      MetaExpressionImpl('_expiration');
}

// === Impl ====================================================================

final class MetaExpressionImpl extends PropertyExpressionImpl
    implements MetaExpressionInterface {
  MetaExpressionImpl(super.propertyPath);
}
