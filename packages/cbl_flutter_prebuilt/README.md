# clb_flutter_prebuilt

This Dart package is used to generate two packages (`cbl_flutter_ce` and
`cbl_flutter_ee`), which implement the
[`cbl_flutter_platform_interface`](../cbl_flutter_platform_interface) by
providing prebuilt official versions of the native libraries (`libcblite` and
`libcblitedart`).

## Generation

[template_package](./template_package) contains the template package which is
used to generate the two packages. Files whose names contain `__template__` are
process as mustache templates with the following context.

| Name                             | Value                            | Type    | Description                                                                              |
| -------------------------------- | -------------------------------- | ------- | ---------------------------------------------------------------------------------------- |
| name                             | cbl_flutter_ce \| cbl_flutter_ee | String  | The name of the package.                                                                 |
| version                          |                                  | String  | The version of the package.                                                              |
| edition                          | community \| enterprise          | String  | The Couchbase Lite edition distributed by the package.                                   |
| enterpriseEdition                |                                  | Boolean | Whether this package is distributing the enterprise edition.                             |
| pluginClass                      | CblFlutterCe \| CblFlutterEe     | String  | The name of the plugin classes.                                                          |
| couchbaseLiteC.version           |                                  | String  | The version of Couchbase Lite C to distribute.                                           |
| couchbaseLiteC.release           |                                  | String  | The name of the release of Couchbase Lite C to distribute.                               |
| couchbaseLiteC.apiPackageRelease |                                  | String  | The name of the release of the `cbl_libcblite_api` package the package is declaring.     |
| couchbaseLiteDart.version        |                                  | String  | The version of Couchbase Lite Dart to distribute.                                        |
| couchbaseLiteDart.release        |                                  | String  | The name of the release of Couchbase Lite Dart to distribute.                            |
| couchbaseLiteC.apiPackageRelease |                                  | String  | The name of the release of the `cbl_libcblitedart_api` package the package is declaring. |
| capitalize                       |                                  | Lambda  | Capitalizes content of the tag.                                                          |

The output file name has `__template__` removed.

All other files are copied as is.

All file paths are interpreted as mustache templates and the rendered string is
used as the output path.

To generate the packages run `dart run` in this packages directory. The packages
are written to `packages/cbl_flutter_ce|ee`.

## Publishing

`cbl_flutter_ce` and `cbl_flutter_ee` are always published together and with the
same version. The changelog needs to be manually updated before publishing and
is published identically for both packages.
