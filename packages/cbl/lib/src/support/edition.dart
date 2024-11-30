import '../bindings.dart';

enum Edition {
  community,
  enterprise,
}

enum EnterpriseFeature {
  localDbReplication,
  databaseEncryption,
  propertyEncryption,
  prediction;

  String get description => switch (this) {
        localDbReplication => 'Local database replication',
        databaseEncryption => 'Database encryption',
        propertyEncryption => 'Property encryption',
        prediction => 'Prediction',
      };
}

Edition get activeEdition =>
    _activeEditionOverride ??
    (CBLBindings.instance.libraries.enterpriseEdition
        ? Edition.enterprise
        : Edition.community);

Edition? _activeEditionOverride;

set activeEditionOverride(Edition? edition) {
  _activeEditionOverride = edition;
}

void useEnterpriseFeature(EnterpriseFeature feature) {
  if (activeEdition != Edition.enterprise) {
    throw StateError(
      '${feature.description} is only available in the Enterprise Edition.',
    );
  }
}
