import 'dart:convert';

// ignore: implementation_imports
import 'package:cbl/src/install.dart';
import 'package:cbl_flutter_install/cbl_flutter_install.dart';
import 'package:mustache_template/mustache.dart';

import 'utils.dart';

JsonMap createTemplateContext({
  required PrebuiltPackageConfiguration configuration,
}) =>
    {
      ...configuration.templateContext(),
      'prebuiltPackageConfigurationJson':
          const JsonEncoder.withIndent('  ').convert(configuration.toJson()),
      'capitalize': capitalize,
    };

extension on PrebuiltPackageConfiguration {
  JsonMap templateContext() => {
        'name': name,
        'cblFlutterInstallVersion': cblFlutterInstallVersion,
        'edition': edition.name,
        'enterpriseEdition': edition == Edition.enterprise,
        'pluginClass': 'CblFlutter${edition.name[0].toUpperCase()}e',
      };
}

String capitalize(LambdaContext context) {
  final text = context.renderString();
  if (text.isEmpty) {
    return text;
  }
  return text.replaceRange(0, 1, text[0].toUpperCase());
}
