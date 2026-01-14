# Building SampleVault

This guide explains how to build and run SampleVault from source.

## Prerequisites

- **macOS 13.0 (Ventura)** or later
- **Xcode 15.0** or later
- **Swift 5.9** or later
- **Command Line Tools** for Xcode

### Installing Xcode

Download Xcode from the Mac App Store or from [Apple Developer](https://developer.apple.com/xcode/).

After installation, ensure command line tools are installed:

```bash
xcode-select --install
```

## Building with Swift Package Manager

SampleVault uses Swift Package Manager for dependency management. The project depends on:

- **GRDB.swift** (SQLite toolkit)
- **AudioKit** (Audio analysis)

### Option 1: Build from Command Line

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/SampleVault.git
   cd SampleVault
   ```

2. **Resolve dependencies**:
   ```bash
   swift package resolve
   ```

3. **Build the project**:
   ```bash
   swift build -c release
   ```

4. **Run the app**:
   ```bash
   swift run
   ```

### Option 2: Build with Xcode

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/SampleVault.git
   cd SampleVault
   ```

2. **Open in Xcode**:
   ```bash
   open Package.swift
   ```

   Xcode will automatically:
   - Resolve Swift Package dependencies
   - Index the project
   - Set up the build system

3. **Select the SampleVault scheme** in the toolbar

4. **Build and run** (⌘R)

## Project Structure

```
SampleVault/
├── Package.swift                 # Swift Package manifest
├── SampleVault/
│   ├── Info.plist               # App metadata
│   ├── SampleVault.entitlements # Sandbox entitlements
│   └── Sources/
│       ├── SampleVaultApp.swift # App entry point
│       ├── Models/              # Data models
│       ├── Database/            # SQLite layer
│       ├── Services/            # Business logic
│       │   ├── AudioPlayer.swift
│       │   ├── WaveformGenerator.swift
│       │   ├── FileScanner.swift
│       │   └── BookmarkManager.swift
│       ├── Views/               # SwiftUI views
│       └── Utils/               # Utilities
└── Resources/                   # Assets
```

## Dependencies

### GRDB.swift

Database abstraction layer providing:
- Type-safe database access
- Full-text search (FTS5)
- Database migrations
- Reactive queries

**Version**: 6.24.0+
**License**: MIT
**Repository**: https://github.com/groue/GRDB.swift

### AudioKit

Audio processing framework providing:
- Audio file I/O
- Signal processing
- Audio analysis (BPM, key detection)
- Real-time audio effects

**Version**: 5.6.0+
**License**: MIT
**Repository**: https://github.com/AudioKit/AudioKit

## Build Configurations

### Debug Build

```bash
swift build -c debug
```

Features:
- Debug symbols included
- Optimizations disabled
- Assertions enabled
- Larger binary size

### Release Build

```bash
swift build -c release
```

Features:
- Optimized for performance
- Debug symbols stripped
- Assertions disabled
- Smaller binary size

## Creating an App Bundle

To create a standalone .app bundle:

1. **Build in release mode**:
   ```bash
   swift build -c release
   ```

2. **Locate the binary**:
   ```bash
   .build/release/SampleVault
   ```

3. **Create app bundle** (manual method):
   ```bash
   mkdir -p SampleVault.app/Contents/MacOS
   mkdir -p SampleVault.app/Contents/Resources

   cp .build/release/SampleVault SampleVault.app/Contents/MacOS/
   cp SampleVault/Info.plist SampleVault.app/Contents/
   ```

4. **Code sign** (optional, for distribution):
   ```bash
   codesign --force --deep --sign - SampleVault.app
   ```

## Development Workflow

### Running Tests

```bash
swift test
```

### Clean Build

```bash
swift package clean
rm -rf .build
swift build
```

### Update Dependencies

```bash
swift package update
```

### Generate Xcode Project (if needed)

```bash
swift package generate-xcodeproj
```

## Troubleshooting

### "Package.resolved file is corrupted"

```bash
rm Package.resolved
swift package resolve
```

### Xcode not finding dependencies

1. Close Xcode
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Reopen project in Xcode
4. Clean build folder (⇧⌘K)
5. Build (⌘B)

### Audio playback not working

- Ensure entitlements are configured correctly
- Check that security-scoped bookmarks are being created
- Verify audio file permissions

### Database errors

- Delete the database file:
  ```bash
  rm ~/Library/Application\ Support/SampleVault/samples.db
  ```
- Restart the app to recreate with latest schema

## Performance Profiling

### Memory Leaks

1. Run with Instruments:
   ```bash
   Product > Profile (⌘I)
   ```
2. Select "Leaks" template
3. Import samples and monitor

### CPU Usage

1. Run with Instruments:
   ```bash
   Product > Profile (⌘I)
   ```
2. Select "Time Profiler" template
3. Identify bottlenecks

## Distribution

### Notarization (macOS 10.14.5+)

1. **Build for release**
2. **Code sign** with Developer ID
3. **Create DMG** or ZIP
4. **Submit for notarization**:
   ```bash
   xcrun notarytool submit SampleVault.dmg \
     --apple-id YOUR_APPLE_ID \
     --team-id YOUR_TEAM_ID \
     --password YOUR_APP_PASSWORD
   ```
5. **Staple ticket**:
   ```bash
   xcrun stapler staple SampleVault.app
   ```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## Support

- **Issues**: https://github.com/samplevault/issues
- **Discussions**: https://github.com/samplevault/discussions
- **Documentation**: https://github.com/samplevault/docs

---

**Note**: SampleVault is sandboxed and requires explicit user permission to access files. Security-scoped bookmarks are used for persistent access.
