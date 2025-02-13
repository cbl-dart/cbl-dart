# Couchbase Lite Installation System

This directory contains the core installation and package management system for Couchbase Lite Dart. It handles downloading, configuring, and loading native libraries across different platforms and architectures.

## Core Components

### Local Assets Configuration
[`local_assets.dart`](./local_assets.dart) manages pre-bundled native libraries:
- Platform-specific path resolution
- Library version management
- Configuration generation
- Library existence verification

### Package Management
[`package.dart`](./package.dart) defines the core package system:
- Library types and configurations
- Platform and architecture support
- Package downloading and installation
- Framework and shared library handling

### Installation Utilities
[`utils.dart`](./utils.dart) provides support functions:
- Archive downloading and unpacking
- Directory operations
- Platform-specific path resolution
- Retry logic for network operations

## Key Features

### Multi-Platform Support
```dart
enum OS {
  android,
  iOS,
  macOS,
  linux,
  windows;
  
  static OS get current => // ... platform detection
}
```

### Library Types
```dart
enum Library {
  cblite,      // Core Couchbase Lite library
  cblitedart,  // Dart bindings
  vectorSearch; // Optional vector search support
}
```

### Edition Support
```dart
enum Edition {
  community,
  enterprise,
}
```

## Package Configuration

### Database Package Configuration
Handles core library and Dart binding packages:
```dart
DatabasePackageConfig({
  required Library library,
  required OS os,
  required List<Architecture> architectures,
  required String release,
  required ArchiveFormat archiveFormat,
  required Edition edition,
})
```

### Vector Search Configuration
Manages vector search extension packages:
```dart
VectorSearchPackageConfig({
  required OS os,
  required List<Architecture> architectures,
  required String release,
})
```

## Installation Process

1. **Package Configuration**
   - Determine platform and architecture
   - Select appropriate package version
   - Configure download settings

2. **Package Download**
   ```dart
   final loader = RemotePackageLoader();
   final package = await loader.load(config);
   ```

3. **Library Setup**
   ```dart
   final config = LocalAssetsConfiguration(
     binaryDependencies: directory,
     edition: Edition.enterprise,
   );
   ```

4. **Verification**
   ```dart
   config.verifyLibrariesExist();
   ```

## Related Components

- [`../bindings/libraries.dart`](../bindings/libraries.dart): Low-level library loading
- [`../bindings/bindings.dart`](../bindings/bindings.dart): Native bindings
- [`../support/isolate.dart`](../support/isolate.dart): Isolate support
- [`../../cbl_dart.dart`](../../../cbl_dart/lib/cbl_dart.dart): Main package entry

## Architecture Support

### Supported Architectures
```dart
enum Architecture {
  ia32,   // 32-bit Intel
  x64,    // 64-bit Intel/AMD
  arm,    // 32-bit ARM
  arm64,  // 64-bit ARM
}
```

### Platform-Specific Features

#### Apple Platforms (iOS/macOS)
- Framework and XCFramework support
- Special version handling
- Code signing support (macOS)

#### Android
- Multi-architecture support
- Architecture-specific library paths
- NDK triplet handling

#### Windows
- DLL directory management
- Architecture-specific binaries

#### Linux
- Shared library (.so) handling
- Architecture triplets
- Multi-architecture support

## Error Handling

The system includes comprehensive error handling for:
- Missing libraries
- Download failures
- Platform incompatibilities
- Architecture mismatches
- Package verification

## Testing

Integration tests can be found in:
[`init_with_local_assets_test.dart`](../../../cbl_dart/test/init_with_local_assets_test.dart)
