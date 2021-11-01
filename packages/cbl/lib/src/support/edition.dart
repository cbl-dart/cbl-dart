import 'ffi.dart';

enum Edition {
  community,
  enterprise,
}

enum EnterpriseFeature {
  localDbReplication,
  databaseEncryption,
  propertyEncryption,
}

Edition get activeEdition =>
    _activeEditionOverride ??
    (cblBindings.libs.enterpriseEdition
        ? Edition.enterprise
        : Edition.community);

Edition? _activeEditionOverride;

set activeEditionOverride(Edition? edition) {
  _activeEditionOverride = edition;
}

void useEnterpriseFeature(EnterpriseFeature feature) {
  if (activeEdition != Edition.enterprise) {
    String featureDescription;
    switch (feature) {
      case EnterpriseFeature.localDbReplication:
        featureDescription = 'Local database replication';
        break;
      case EnterpriseFeature.databaseEncryption:
        featureDescription = 'Database encryption';
        break;
      case EnterpriseFeature.propertyEncryption:
        featureDescription = 'Property encryption';
        break;
    }
    throw StateError(
      '$featureDescription is only available in the Enterprise Edition.',
    );
  }
}
