import 'package:mustache_template/mustache.dart';

import 'configuration.dart';
import 'utils.dart';

JsonMap createTemplateContext({required PackageConfiguration configuration}) =>
    {
      ...configuration.templateContext(),
      'capitalize': capitalize,
    };

extension on LibraryInfo {
  JsonMap templateContext() => {
        'version': version,
        'release': release,
        'apiPackageRelease': apiPackageRelease,
      };
}

extension on PackageConfiguration {
  JsonMap templateContext() => {
        'name': name,
        'version': version,
        'edition': edition.name,
        'enterpriseEdition': edition == Edition.enterprise,
        'pluginClass': 'CblFlutter${edition.name[0].toUpperCase()}e',
        'couchbaseLiteC': couchbaseLiteC.templateContext(),
        'couchbaseLiteDart': couchbaseLiteDart.templateContext(),
      };
}

String capitalize(LambdaContext context) {
  final text = context.renderString();
  if (text.isEmpty) {
    return text;
  }
  return text.replaceRange(0, 1, text[0].toUpperCase());
}
