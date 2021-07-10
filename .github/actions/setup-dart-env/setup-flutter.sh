#!/bin/bash

set -e

flutterVersion="$1"

flutterDir="$RUNNER_TOOL_CACHE/flutter"
flutterBinDir="$flutterDir/bin"
pubBinDir="$HOME/.pub-cache/bin"

echo "Installing Flutter SDK version $flutterVersion"

echo "Cloning Flutter repository..."
git clone https://github.com/flutter/flutter.git -b "$flutterVersion" --depth 1 "$flutterDir" >/dev/null

# Add Flutter binaries to path
echo "$flutterBinDir" >>$GITHUB_PATH

# Add global pub binaries to path
echo "$pubBinDir" >>$GITHUB_PATH

# Make binaries availabe to comands in this action
export PATH="$pubBinDir:$flutterBinDir:$PATH"
echo "export PATH=\"$pubBinDir:$flutterBinDir:\$PATH\"" >"update_flutter_path.sh"
chmod 755 update_flutter_path.sh

echo "Warming up Flutter CLI..."
# Run tool once so that the next command does not show verbose install info.
flutter >/dev/null

echo "Succefully installed Flutter SDK:"
# Print Flutter version
flutter --version
