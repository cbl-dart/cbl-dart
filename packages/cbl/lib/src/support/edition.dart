import '../bindings/cblitedart.dart' as cblitedart;

enum Edition { community, enterprise }

Edition get activeEdition =>
    _activeEditionOverride ??
    (cblitedart.CBLDart_IsEnterprise()
        ? Edition.enterprise
        : Edition.community);

Edition? _activeEditionOverride;

set activeEditionOverride(Edition? edition) {
  _activeEditionOverride = edition;
}

void requireEnterprise(String capability) {
  if (activeEdition != Edition.enterprise) {
    throw StateError(
      '$capability is only available in the Enterprise Edition.',
    );
  }
}
