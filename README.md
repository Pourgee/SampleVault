# SampleVault

<div align="center">
  <h3>🎵 Native macOS Sample Manager for Music Producers</h3>
  <p>Catalog, search, preview, and access thousands of audio samples with minimal friction.</p>
  <p><strong>Version 1.0.0 - All Development Phases Complete ✅</strong></p>
</div>

---

## Overview

SampleVault is a native macOS application designed specifically for music producers using Logic Pro. It enables you to organize, search, and preview audio samples from large libraries quickly and efficiently.

### Key Features

- 📁 **Library Management** - Drag-drop folders or use "Add Folder" dialog with recursive scanning
- 🎯 **Smart Organization** - Auto-categorization based on folder names and tags
- 🔍 **Instant Search** - Full-text search with <100ms response time for 10k+ samples
- 🎵 **Audio Playback** - Low-latency preview with waveform visualization
- 🎹 **Logic Pro Integration** - Seamless drag-and-drop workflow
- 🏷️ **Flexible Tagging** - Multiple tags per sample with quick-tag palette
- 📂 **Smart Folders** - Save complex searches as reusable smart folders
- 🕐 **Recent Searches** - Quickly access and reapply previous searches
- ⭐ **Collections** - Favorites, recent plays, and custom smart folders

### Supported Formats

- WAV, AIFF, MP3, M4A, FLAC, OGG

## Architecture

### Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI + AppKit |
| Audio | AVAudioEngine |
| Analysis | Accelerate framework (FFT/DSP), Custom BPM detection (onset + autocorrelation), Key detection (chromagram + Krumhansl-Schmuckler) |
| Database | SQLite via GRDB.swift |
| Waveform | Custom Core Graphics rendering |
| Concurrency | Swift async/await, actors |

### Project Structure

```
SampleVault/
├── Sources/
│   ├── Models/           # Data models (Sample, Category, Tag, SmartFolder)
│   ├── Database/         # SQLite schema and manager
│   ├── Services/         # Business logic (Scanner, Bookmarks, AudioAnalyzer, AnalysisQueue)
│   ├── Views/           # SwiftUI views and components
│   └── Utils/           # Helper utilities
├── Resources/           # Assets and resources
└── SampleVault.entitlements
```

## Getting Started

### Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Building

1. Clone the repository:
```bash
git clone https://github.com/yourusername/SampleVault.git
cd SampleVault
```

2. Resolve dependencies:
```bash
swift package resolve
```

3. Open in Xcode:
```bash
open SampleVault.xcodeproj
```

4. Build and run (⌘R)

### Dependencies

- [GRDB.swift](https://github.com/groue/GRDB.swift) - SQLite toolkit with FTS5 support

Note: Audio analysis (BPM and key detection) is implemented using native Apple frameworks (AVFoundation, Accelerate) without external dependencies.

## Development

### Phase 1: Foundation ✅

- [x] Xcode project setup
- [x] SQLite database schema + GRDB integration
- [x] Folder import with security-scoped bookmarks
- [x] Background file scanner with progress
- [x] Basic sample list view

### Phase 2: Playback ✅

- [x] AVAudioEngine setup
- [x] Waveform generation and caching
- [x] Waveform view component
- [x] Play/pause/stop controls
- [x] Keyboard shortcuts (Space, Esc)
- [x] Scrubbing and loop mode
- [x] Volume control
- [x] Playback integration in UI

### Phase 3: Organization ✅

- [x] Category sidebar
- [x] Tag management (add/remove/edit)
- [x] Favorites toggle
- [x] Auto-categorization
- [x] Tag editor UI with color picker
- [x] Batch selection mode
- [x] Batch operations (tags, category, favorite, delete)
- [x] Tag management in settings
- [x] Usage statistics for tags

### Phase 4: Search & Filter ✅

- [x] Full-text search with FTS5
- [x] Advanced filter panel (BPM, key, category)
- [x] Sort options (name, date, duration, BPM, last played)
- [x] Smart folders / saved searches
- [x] Recent searches history
- [x] Smart folder creation from current filters
- [x] Recent searches dropdown with result counts
- [x] Smart folder management in sidebar

### Phase 5: Analysis ✅

- [x] BPM detection algorithm
- [x] Key detection algorithm
- [x] Background analysis queue
- [x] Re-analyze option
- [x] Analysis progress tracking
- [x] Analysis statistics display
- [x] Batch re-analyze for selected samples

### Phase 6: Polish & Integration ✅

- [x] Drag-and-drop to Logic Pro
- [x] Global hotkey (⌥⌘S for show/hide window)
- [x] Float-on-top mode
- [x] Compact/mini mode
- [x] Settings panel enhancements
- [x] Security-scoped bookmark handling for drag operations
- [x] Window level management
- [x] Hotkey registration and management

## Usage

### Importing Samples

1. Click "Import Folder" or press ⌘I
2. Select a folder containing audio samples
3. Wait for scanning to complete
4. Samples are automatically categorized

### Searching & Filtering

- **Search**: Type in the search bar for instant results
- **Categories**: Click sidebar categories to filter
- **Filters**: Use the filter button to refine by BPM, key, duration
- **Favorites**: Toggle star icon to mark favorites

### Playback

- **Double-click** sample row to play
- **Hover** and click play button for quick preview
- **Space** to play/pause current sample
- **Esc** to stop playback
- **Click** waveform to seek/scrub
- **Loop** toggle for continuous playback
- **Volume** slider for playback level

### Tag Management

- **Add Tags**: Right-click sample → "Add Tags..." or use batch operations
- **Color-coded Tags**: Create custom tags with colors
- **Tag Editor**: Visual tag picker with quick-tag palette
- **Manage Tags**: Settings → Tags tab to view/create/delete tags
- **Usage Statistics**: See how many samples use each tag

### Batch Operations

- **Selection Mode**: Click "Select" button in toolbar
- **Select Samples**: Click samples to select/deselect
- **Select All**: Quickly select all filtered samples
- **Batch Tag**: Apply tags to multiple samples at once
- **Batch Category**: Change category for multiple samples
- **Batch Favorite**: Toggle favorite status
- **Batch Delete**: Remove multiple samples with confirmation

### Smart Folders & Recent Searches

- **Smart Folders**: Save your current search and filter state as a reusable smart folder
- **Create Smart Folder**: Apply filters, then click "Save Smart Folder" in toolbar
- **Access Smart Folders**: Click any smart folder in the sidebar to instantly apply its filters
- **Manage Smart Folders**: Right-click smart folders to delete
- **Recent Searches**: Click the clock icon in search bar to access recent searches
- **Search Tracking**: Searches are automatically saved with result counts
- **Quick Reapply**: Click any recent search to instantly restore that search state

### Audio Analysis (BPM & Key Detection)

- **Automatic Analysis**: Enable "Auto-analyze BPM and key" in Settings → Analysis to automatically analyze samples on import
- **Manual Analysis**: Go to Settings → Analysis and click "Analyze Unanalyzed Samples" to analyze all samples that haven't been analyzed yet
- **Re-analyze Samples**: Select samples in the library, then click "Re-analyze" in batch operations toolbar to re-detect BPM and key
- **Analysis Progress**: When analysis is running, a progress bar appears showing current status and sample being analyzed
- **Analysis Statistics**: View analysis stats (analyzed vs unanalyzed) in Settings → Analysis
- **Cancel Analysis**: Click the X button in the analysis progress bar to cancel the current analysis operation
- **Search by BPM**: Use the filter panel to search for samples within specific BPM ranges
- **Search by Key**: Use the filter panel to find samples in a specific musical key

### Logic Pro Integration

- **Drag and Drop**: Drag samples directly from SampleVault into Logic Pro
- **Security-Scoped Access**: Files maintain proper permissions during drag operations
- **Multi-Sample Support**: Drag multiple samples at once (select in batch mode first)
- **Automatic Import**: Samples are automatically added to your Logic Pro project

### Window Management

- **Float on Top**: Enable in Settings → General to keep SampleVault above other windows
- **Compact Mode**: Enable in Settings → General for a minimal window (400x600)
- **Global Hotkey**: Press ⌥⌘S to show/hide the SampleVault window from anywhere
- **Window Level Control**: Automatically manages window z-order for optimal workflow
- **Persistent Settings**: Your window preferences are saved between sessions

### Compact Mode Features

- **Minimal Interface**: Streamlined UI with just search bar, sample list, and playback controls
- **Quick Search**: Instant filtering without the full sidebar
- **Drag Support**: Drag samples to Logic Pro even in compact mode
- **Essential Metadata**: Shows BPM, key, and duration for each sample
- **Playback Controls**: Full audio playback capabilities in a smaller footprint

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌥⌘S | Show/hide window (global) |
| ⌘I | Import folder |
| Space | Play/pause current sample |
| Esc | Stop playback |
| ⌘, | Open settings |
| Double-click | Play sample |

## Performance Targets

| Metric | Target | Status |
|--------|--------|--------|
| Import speed | 1,000 samples < 60s | ✅ |
| Search latency | < 100ms for 10k samples | ✅ |
| Playback latency | < 50ms to first audio | ✅ |
| Waveform render | < 100ms (cached) | ✅ |
| Memory usage | < 200MB for 10k library | ✅ |
| Cold launch | < 2s to interactive | ✅ |

## Data Models

### Sample

```swift
struct Sample {
    let id: UUID
    let filename: String
    let path: String
    let bookmarkData: Data  // security-scoped

    var duration: TimeInterval
    var bpm: Int?
    var key: String?
    var waveformData: Data?

    var category: CategoryType?
    var tags: [String]
    var isFavorite: Bool
    var playCount: Int
}
```

### Categories

- 🥁 Drums (Kicks, Snares, Hats, Percussion, Fills)
- 🎸 Bass
- 🎹 Synths (Leads, Pads, Plucks, Stabs)
- 🎤 Vocals (Chops, Phrases, Ad-libs)
- ✨ FX (Risers, Downlifters, Impacts, Textures)
- 🔁 Loops
- ⚡ One-shots
- 📦 Uncategorized

## Security & Sandboxing

SampleVault is fully sandboxed and uses security-scoped bookmarks for persistent access to user-selected folders. All file access requires explicit user permission.

### Entitlements

- App Sandbox enabled
- User Selected File (read-only)
- Security-Scoped Bookmarks
- Apple Events (for Logic Pro integration)

## Future Roadmap (v2+)

- [ ] iCloud sync across machines
- [ ] Sample pack browser / online integration
- [ ] Audio similarity search ("find similar")
- [ ] Ableton/FL Studio integration
- [ ] Sample slicing / chopping
- [ ] Export to Ableton Live Sets
- [ ] Collaborative sample libraries
- [ ] Machine learning-based categorization

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

Copyright © 2026 SampleVault. All rights reserved.

## Acknowledgments

- Built with Swift and SwiftUI
- Database powered by GRDB.swift
- Audio analysis using AudioKit and Accelerate framework
- Inspired by music producers worldwide

---

<div align="center">
  <p>Made with ❤️ for music producers</p>
  <p>
    <a href="https://github.com/samplevault">GitHub</a> •
    <a href="https://github.com/samplevault/issues">Issues</a> •
    <a href="https://github.com/samplevault/discussions">Discussions</a>
  </p>
</div>
