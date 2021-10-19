# cbl_flutter_local

Implementation of [cbl_flutter](../cbl_flutter) for local development and
testing and CI.

[dev-tools.sh](../../tools/dev-tools.sh)'s `prepareNativeLibraries` command
populates platform specific directories of this plugin with the native libraries
(`cblite` and `cblitedart`).

[cbl_e2e_tests_flutter](../cbl_e2e_tests_flutter) in turn depends on this
package, to make those libraries available for testing.
