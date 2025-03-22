# Local Assets Configuration System

## Prerequisites

Before using the Local Assets Configuration system, you need to download the required platform-specific libraries using the provided `scripts/download_local_assets.sh` script.

### Setting Up the Download Script

1. **Make the Script Executable**

First, make the script executable by running:
```bash
chmod +x scripts/download_local_assets.sh
```

2. **Basic Usage**
```bash
# Navigate to the cbl package directory
cd packages/cbl

# Run the script with default options
./scripts/download_local_assets.sh

# Or with specific options
./scripts/download_local_assets.sh --dir local_assets --platform macos
```

3. **Available Options**
```bash
Options:
  -d, --dir DIR                 Output directory (default: assets)
  -p, --platform PLATFORM       Target platform: all, windows, macos, linux (default: all)
  -c, --cbl-version VERSION     Couchbase Lite version (default: 3.2.0)
  -t, --cblitedart VERSION      CBLiteDart version (default: 8.0.0)
  -v, --vector-search VERSION   Vector Search version (default: 1.0.0)
  -e, --edition EDITION         Edition: enterprise or community (default: enterprise)
  -h, --help                    Show this help message
```

4. **Example Commands**
```bash
# Download all platforms with default settings
./scripts/download_local_assets.sh

# Download only macOS libraries to a custom directory
./scripts/download_local_assets.sh -d my_libraries -p macos

# Download community edition for Windows
./scripts/download_local_assets.sh --platform windows --edition community

# Download specific versions
./scripts/download_local_assets.sh \
  --cbl-version 3.2.1 \
  --cblitedart 8.0.1 \
  --vector-search 1.0.1
```

5. **Output Structure**
The script creates a directory structure like:
```
output_directory/
├── macos/
│   ├── libcblite.3.dylib
│   ├── libcblitedart.8.dylib
│   └── CouchbaseLiteVectorSearch.framework/
├── windows/
│   ├── cblite.dll
│   ├── cblitedart.dll
│   └── CouchbaseLiteVectorSearch.dll
└── linux/
    ├── libcblite.so
    ├── libcblitedart.so
    └── CouchbaseLiteVectorSearch.so
```

6. **Verification**
The script automatically verifies:
- Download integrity
- File existence
- Framework structure (for macOS)
- Required symlinks

7. **Troubleshooting**

If you encounter permission issues:
```bash
# Make sure the script is executable
chmod +x scripts/download_local_assets.sh

# If you get "Permission denied" when creating directories
sudo ./scripts/download_local_assets.sh

# If curl is not installed
# For Ubuntu/Debian:
sudo apt-get install curl

# For macOS:
brew install curl
```

Common issues and solutions:
- **"curl: command not found"**: Install curl using your system's package manager
- **"unzip: command not found"**: Install unzip utility
- **Permission denied**: Ensure you have write permissions in the target directory
- **Invalid zip file**: Check your internet connection and try again

## Overview

The `LocalAssetsConfiguration` class works in conjunction with [`../bindings/libraries.dart`](../bindings/libraries.dart) to handle:
- Platform-specific library paths
- Version management
- Library configuration
- Existence verification

## Platform-Specific Directory Structures

### Directory Layout
The `binaryDependencies` directory must follow this structure:
```
binaryDependencies/
├── macos/
│   └── c4f61c9bde1085be63f32dd54ca8829e/
│       ├── libcblite.3.dylib
│       ├── libcblitedart.8.dylib
│       └── CouchbaseLiteVectorSearch.framework/
│           └── Versions/
│               └── A/
│                   └── CouchbaseLiteVectorSearch
├── windows/
│   └── c2ddf39c36bd6ab58d86b27ddc102286/
│       ├── cblite.dll
│       ├── cblitedart.dll
│       └── CouchbaseLiteVectorSearch.dll
└── linux/
    └── 6af4f73a0a0e59cb7e1a272a9fa0828a/
        ├── libcblite.so
        ├── libcblitedart.so
        └── libCouchbaseLiteVectorSearch.so
```

### Platform-Specific Details

#### macOS Libraries
- **File Extensions**: `.dylib` for dynamic libraries, `.framework` for frameworks
- **Naming Convention**: 
  - Dynamic Libraries: `lib{name}.{version}.dylib`
  - Frameworks: `{name}.framework/Versions/A/{name}`
- **Required Files**:
  - `libcblite.3.dylib`: Core Couchbase Lite library (version 3)
  - `libcblitedart.8.dylib`: Dart bindings (version 8)
  - `CouchbaseLiteVectorSearch.framework`: Vector search capability (optional)
- **Version Numbers**: Explicitly included in filename for dynamic libraries
- **Framework Structure**: Uses Apple's standard framework directory layout

#### Windows Libraries
- **File Extension**: `.dll`
- **Naming Convention**: `{name}.dll`
- **Required Files**:
  - `cblite.dll`: Core Couchbase Lite library
  - `cblitedart.dll`: Dart bindings
  - `CouchbaseLiteVectorSearch.dll`: Vector search capability (optional)
- **Version Handling**: Versions embedded in DLL metadata
- **Path Requirements**: Must be in a directory registered in the system PATH or use `AddDllDirectory`

#### Linux Libraries
- **File Extension**: `.so`
- **Naming Convention**: `lib{name}.so`
- **Required Files**:
  - `libcblite.so`: Core Couchbase Lite library
  - `libcblitedart.so`: Dart bindings
  - `libCouchbaseLiteVectorSearch.so`: Vector search capability (optional)
- **Symbolic Links**: May use symlinks for version management
- **Loading Behavior**: Uses standard Linux shared library loading mechanisms

### Hash Directory Purpose
Each platform directory contains a subdirectory named with a specific hash:
- macOS: `c4f61c9bde1085be63f32dd54ca8829e`
- Windows: `c2ddf39c36bd6ab58d86b27ddc102286`
- Linux: `6af4f73a0a0e59cb7e1a272a9fa0828a`

These hash directories serve multiple purposes:
1. **Version Control**: Ensures correct binary version for each platform
2. **Compatibility Checking**: Validates binary compatibility
3. **Isolation**: Keeps different versions of libraries separate
4. **Update Management**: Facilitates atomic updates of library sets

### Usage Example
```dart
final config = LocalAssetsConfiguration(
  // Point to the root directory containing platform-specific subdirectories
  binaryDependencies: Directory('path/to/binaryDependencies'),
  edition: Edition.enterprise,
  skipVectorSearch: false, // Set to true if vector search is not needed
);

// The system will automatically:
// 1. Detect the current platform
// 2. Use the appropriate hash directory
// 3. Load the correct library versions
// 4. Handle platform-specific naming conventions
```

## Core Components

### LocalAssetsConfiguration
```dart
class LocalAssetsConfiguration {
  LocalAssetsConfiguration({
    required Directory binaryDependencies,
    required Edition edition,
    bool skipVectorSearch = false,
  });
}
```

### Required Libraries
Three main libraries are managed:
- `cblite`: Core Couchbase Lite library
- `cblitedart`: Dart-specific bindings
- `vectorSearch`: Optional vector search capabilities (can be skipped)

## Detailed Flow

### 1. Configuration Initialization
```dart
// Create configuration with binary dependencies directory
final config = LocalAssetsConfiguration(
  binaryDependencies: Directory('path/to/libraries'),
  edition: Edition.enterprise,
  skipVectorSearch: false,
);
```

### 2. Platform Path Resolution
The system determines platform-specific paths through two key properties:

```dart
// Platform directory determination
String _platformDir => switch (Platform.operatingSystem) {
  'macos' => 'macos',
  'windows' => 'windows',
  'linux' => 'linux',
  _ => throw UnsupportedError('Unsupported platform'),
};

// Platform-specific hash for versioning
String _platformHash => switch (Platform.operatingSystem) {
  'macos' => 'c4f61c9bde1085be63f32dd54ca8829e',
  'windows' => 'c2ddf39c36bd6ab58d86b27ddc102286',
  'linux' => '6af4f73a0a0e59cb7e1a272a9fa0828a',
  _ => throw UnsupportedError('Unsupported platform'),
};
```

### 3. Library Configuration Creation
The system creates configurations for each required library:

1. **Base Configuration Creation**:
```dart
LibrariesConfiguration toLibrariesConfiguration() {
  final os = OS.current;
  return LibrariesConfiguration(
    directory: librariesPath,
    enterpriseEdition: edition == Edition.enterprise,
    cbl: _createLibraryConfig(os, Library.cblite),
    cblDart: _createLibraryConfig(os, Library.cblitedart),
    vectorSearch: skipVectorSearch ? null : _createLibraryConfig(os, Library.vectorSearch),
  );
}
```

2. **Individual Library Configuration**:
```dart
LibraryConfiguration _createLibraryConfig(OS os, Library library) {
  final name = library.libraryName(os);
  final isAppleFramework = library.appleFrameworkType(os) == AppleFrameworkType.framework;
  
  // Version handling for macOS
  final version = os == OS.macOS && !isAppleFramework
      ? switch (library) {
          Library.cblite => '3',
          Library.cblitedart => '8',
          Library.vectorSearch => null,
        }
      : null;

  return LibraryConfiguration.dynamic(
    name,
    version: version,
    isAppleFramework: isAppleFramework,
  );
}
```

### 4. Path Resolution
The system resolves full paths for libraries:

```dart
String _resolveLibraryPath(LibraryConfiguration config) {
  // Platform-specific extension determination
  final extension = switch (os) {
    OS.macOS => '.dylib',
    OS.linux => '.so',
    OS.windows => '.dll',
    _ => throw UnsupportedError('Unsupported platform'),
  };

  // Special handling for Apple frameworks
  if (config.isAppleFramework ?? false) {
    return join(librariesPath, '$libraryName.framework', 'Versions', 'A', libraryName);
  }

  // Version-aware path construction
  return version == null
      ? join(librariesPath, '$libraryName$extension')
      : join(librariesPath, '$libraryName.$version$extension');
}
```

### 5. Verification
The system verifies all required libraries exist:

```dart
void verifyLibrariesExist() {
  final os = OS.current;
  final libraryConfigs = [
    _createLibraryConfig(os, Library.cblite),
    _createLibraryConfig(os, Library.cblitedart),
    if (!skipVectorSearch) _createLibraryConfig(os, Library.vectorSearch),
  ];

  // Verify each library exists
  for (final config in libraryConfigs) {
    final path = _resolveLibraryPath(config);
    if (!File(path).existsSync()) {
      throw StateError('Required library not found at: $path');
    }
  }
}
```

## Integration Points

### With LibraryConfiguration
The system integrates with [`../bindings/libraries.dart`](../bindings/libraries.dart) for:
- Dynamic library loading
- Path resolution
- Platform-specific library handling

### Testing
Integration tests can be found in [`../../../cbl_dart/test/init_from_local_assets_test.dart`](../../../cbl_dart/test/init_from_local_assets_test.dart)

## Platform-Specific Considerations

### macOS
- Handles both frameworks and dynamic libraries
- Special version handling (e.g., version '3' for cblite)
- Framework structure: `name.framework/Versions/A/name`

### Windows
- Uses .dll extension
- Standard library naming

### Linux
- Uses .so extension
- Standard library naming

## Error Handling

The system includes error handling for:
- Unsupported platforms
- Missing libraries
- Invalid configurations

For implementation details, see the full source in [`from_local_assets.dart`](./from_local_assets.dart).

## System Integration Map

### Core Dependencies and Flow

1. **Entry Point** [`../../cbl_dart.dart`](../../../cbl_dart/lib/cbl_dart.dart)
   - Provides public initialization API
   - Coordinates the entire library loading process
   ```dart
   void initWithLocalAssets({
     required Directory binaryDependencies,
     Edition edition = Edition.community,
   }) {
     // Creates LocalAssetsConfiguration
     final config = LocalAssetsConfiguration(
       binaryDependencies: binaryDependencies,
       edition: edition,
     );
     
     // Verifies library existence
     config.verifyLibrariesExist();
     
     // Converts to library configuration
     final libConfig = config.toLibrariesConfiguration();
     
     // Initializes the system
     _initializeWithConfig(libConfig);
   }
   ```

2. **Library Configuration** [`../bindings/libraries.dart`](../bindings/libraries.dart)
   - Manages low-level library configurations
   - Handles dynamic library loading
   - Key Classes:
     ```dart
     class LibraryConfiguration {
       // Dynamic library configuration
       LibraryConfiguration.dynamic(
         String? name, {
         bool? appendExtension,
         String? version,
         bool? isAppleFramework,
       });
     
       // Process library configuration
       LibraryConfiguration.process();
     
       // Actual library loading
       DynamicLibrary _load({String? directory}) {
         // Platform-specific loading logic
       }
     }
     ```

3. **Native Bindings** [`../bindings/bindings.dart`](../bindings/bindings.dart)
   - Bridges Dart code to native libraries
   - Manages native function pointers
   - Integration Example:
     ```dart
     class DynamicLibraries {
       factory DynamicLibraries.fromConfig(LibrariesConfiguration config) {
         // Loads all required libraries
         return DynamicLibraries._(
           enterpriseEdition: config.enterpriseEdition,
           cbl: config.cbl._load(directory: config.directory),
           cblDart: config.cblDart._load(directory: config.directory),
           vectorSearchLibraryPath: config.vectorSearch?.tryResolvePath(...),
         );
       }
     }
     ```

4. **Base Bindings** [`../bindings/base.dart`](../bindings/base.dart)
   - Provides core FFI utilities
   - Handles symbol resolution
   - Platform-specific binding details
   ```dart
   // Example of symbol lookup and binding
   T lookupFunction<T extends Function>(
     DynamicLibrary library,
     String symbolName,
   ) {
     return library
         .lookup<NativeFunction<T>>(symbolName)
         .asFunction<T>();
   }
   ```

5. **Isolate Support** [`../support/isolate.dart`](../support/isolate.dart)
   - Ensures thread-safe library initialization
   - Manages library state across isolates
   - Key functionality:
     ```dart
     Future<void> initializeIsolate() async {
       // Ensures libraries are properly loaded in new isolates
       if (!_isInitialized) {
         await _initialize();
       }
     }
     ```

6. **Tracing System** [`../tracing.dart`](../tracing.dart)
   - Provides debugging infrastructure
   - Logs library loading process
   - Integration points:
     ```dart
     void trace(String message) {
       if (_isEnabled) {
         print('[CBL] $message');
       }
     }
     ```

### Complete Integration Flow

1. **Initialization Request**
   ```dart
   initWithLocalAssets(
     binaryDependencies: directory,
     edition: Edition.enterprise,
   )
   ```

2. **Configuration Creation**
   ```dart
   LocalAssetsConfiguration config = LocalAssetsConfiguration(...)
   ```

3. **Library Path Resolution**
   ```dart
   String libraryPath = config.librariesPath
   ```

4. **Library Configuration Generation**
   ```dart
   LibrariesConfiguration libConfig = config.toLibrariesConfiguration()
   ```

5. **Dynamic Library Loading**
   ```dart
   DynamicLibraries libraries = DynamicLibraries.fromConfig(libConfig)
   ```

6. **Native Binding Initialization**
   ```dart
   initializeBindings(libraries)
   ```

7. **Isolate Setup**
   ```dart
   await initializeIsolate()
   ```

### Error Handling and Verification Flow

1. **Configuration Validation**
   - Checks for required parameters
   - Validates platform compatibility
   - Verifies edition settings

2. **Path Resolution Verification**
   - Ensures directory existence
   - Validates path structure
   - Checks platform-specific requirements

3. **Library Loading Verification**
   - Verifies library existence
   - Checks symbol availability
   - Validates version compatibility

4. **Runtime Verification**
   - Ensures proper initialization
   - Validates library functionality
   - Checks isolate state

## Testing

### Unit Tests
Complete test coverage can be found in:
[`init_from_local_assets_test.dart`](../../../cbl_dart/test/init_from_local_assets_test.dart)

Key test scenarios:
```dart
// Configuration tests
test('creates correct configuration for enterprise edition', () {
  final config = LocalAssetsConfiguration(
    binaryDependencies: directory,
    edition: Edition.enterprise,
  );
  // ... test assertions
});

// Path resolution tests
test('resolves correct library paths for platform', () {
  // ... test implementation
});

// Library verification tests
test('verifies existence of required libraries', () {
  // ... test implementation
});
```

### Test Coverage Areas
1. **Configuration Creation**
   - Edition handling
   - Vector search options
   - Platform detection

2. **Path Resolution**
   - Platform-specific paths
   - Version handling
   - Framework detection

3. **Library Verification**
   - Missing library detection
   - Invalid configuration handling
   - Platform compatibility

4. **Integration Tests**
   - Full system initialization
   - Cross-platform compatibility
   - Error handling scenarios

For detailed test implementations and additional scenarios, see the [test file](../../../cbl_dart/test/init_from_local_assets_test.dart).
