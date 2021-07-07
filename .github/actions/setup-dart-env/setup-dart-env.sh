set -e

flutterVersion="$1"
melosVersion="$2"
flutterDir="$HOME/opt/flutter"
flutterBinDir="$flutterDir/bin"
dartBinDir="$flutterDir/bin/cache/dart-sdk/bin"
flutter="$flutterBinDir/flutter"
pubBinDir="$HOME/.pub-cache/bin"
melos="$pubBinDir/melos"

if [[ -z "$melosVersion" ]]; then
    echo "::error::Melos version must not be empty."
    exit 1
fi

# Add Flutter binaries to path
echo "$flutterBinDir" >>$GITHUB_PATH

# Add Dart binaries to path
echo "$dartBinDir" >>$GITHUB_PATH

# Add global pub binaries to path
echo "$pubBinDir" >>$GITHUB_PATH

# Make binaries availabe to comands in this script
export PATH="$pubBinDir:$dartBinDir:$flutterBinDir:$PATH"

echo "::group::Clone Flutter repo"

git clone https://github.com/flutter/flutter.git -b "$flutterVersion" --depth 1 "$flutterDir"

echo "::endgroup::"

echo "::group::Flutter version"

# Print Flutter version
"$flutter" --version

echo "::endgroup::"

echo "::group::Install Melos"

"$flutter" pub global activate melos "$melosVersion"

echo "::endgroup::"

if [ -z "$SKIP_MELOS_BOOTSTRAP" ]; then
    echo "::group::Bootstrap packages with Melos"

    "$melos" bootstrap

    echo "::endgroup::"
fi
