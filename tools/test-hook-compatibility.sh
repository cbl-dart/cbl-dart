#!/bin/bash
set -euo pipefail

# Resolve as an application outside the Flutter workspace: package consumers
# must support cbl's minimum SDK independently of workspace dev dependencies.
repo_dir=$(cd "$(dirname "$0")/.." && pwd)
mode=${1:?Expected legacy, hooks2, code2, or latest}
case "$mode" in
legacy)
    hooks=1.0.0
    code_assets=1.0.0
    native_toolchain_c=0.17.6
    ;;
hooks2)
    hooks=2.0.0
    code_assets=1.1.0
    native_toolchain_c=0.19.0
    ;;
code2)
    hooks=2.2.0
    code_assets=2.0.0
    native_toolchain_c=0.19.4
    ;;
latest)
    hooks='^2.2.0'
    code_assets='^2.1.0'
    native_toolchain_c='^0.19.5'
    ;;
*)
    echo "Unknown dependency configuration: $mode" >&2
    exit 1
    ;;
esac

app_dir=$(mktemp -d)
trap 'rm -rf "$app_dir"' EXIT
cat > "$app_dir/pubspec.yaml" <<EOF
name: cbl_hook_compatibility
environment:
  sdk: ^3.10.0
dependencies:
  cbl:
    path: '$repo_dir/packages/cbl'
  hooks: '$hooks'
  code_assets: '$code_assets'
  native_toolchain_c: '$native_toolchain_c'
EOF
# FRB itself has no build hook. Applications using its generated Rust hooks
# constrain hooks/code_assets directly, as this fixture does.
if [[ "$mode" != legacy ]]; then
    echo "  flutter_rust_bridge: ^2.13.0" >> "$app_dir/pubspec.yaml"
fi
cp "$repo_dir/packages/cbl/test/hook/compatibility_smoke.dart" "$app_dir/main.dart"
cd "$app_dir"
dart pub get
dart pub deps --style=compact
dart run main.dart

