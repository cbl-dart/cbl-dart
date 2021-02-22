# - name: Install melos
#   run: dart pub global activate melos "$MELOS_VERSION"

# - name: Bootstrap packages with melos
#   run: melos bootstrap

set -e

flutterChannel="$1"
melosVersion="$2"
flutterDir="$HOME/opt/flutter"
flutterBinDir="$flutterDir/bin"
flutter="$flutterBinDir/flutter"
pubBinDir="$HOME/.pub-cache/bin"
melos="$pubBinDir/melos"
channels=(stable beta dev master)

# Validate channel
if [[ ! " ${channels[@]} " =~ " ${flutterChannel} " ]]; then
    echo "::error::Flutter channel '${flutterChannel}' does not exist."
    exit 1
fi

if [[ -z "$melosVersion" ]]; then
    echo "::error::Melos version must not be empty."
    exit 1
fi

# Add Flutter bin to path
echo "$flutterBinDir" >>$GITHUB_PATH

# Add pub bins to path
echo "$pubBinDir" >>$GITHUB_PATH

# Make bin dir availabe to comands in this script
export PATH="$flutterBinDir:$pubBinDir:$PATH"

echo "::group::Clone Flutter repo"

git clone https://github.com/flutter/flutter.git -b "$flutterChannel" --depth 1 "$flutterDir"

echo "::endgroup::"

echo "::group::Flutter version"

# Print Flutter version
"$flutter" --version

echo "::endgroup::"

echo "::group::Install Melos"

"$flutter" pub global activate melos "$melosVersion"

echo "::endgroup::"

echo "::group::Bootstrap packages with Melos"

"$melos" bootstrap

echo "::endgroup::"
