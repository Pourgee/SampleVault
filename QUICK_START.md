# SampleVault Quick Start Guide

## 🚀 Running on Your Mac

### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- 200MB free disk space

### Step-by-Step Instructions

1. **Get the Code on Your Mac**
   ```bash
   # Option A: Clone from git
   git clone <your-repo-url>
   cd SampleVault
   git checkout claude/samplevault-macos-app-mqQqU

   # Option B: Download the ZIP and extract it
   ```

2. **Open in Xcode**
   ```bash
   cd SampleVault
   open Package.swift
   ```

   Or simply double-click `Package.swift` in Finder.

3. **Wait for Dependencies** (first time only)
   - Xcode will show "Resolving Package Dependencies"
   - This downloads GRDB.swift (~30-60 seconds)
   - Wait until you see "Ready" in the status bar

4. **Build and Run**
   - Press **⌘R** or click the ▶️ Play button
   - The app will compile and launch!

## 🎵 First Use

Once the app launches:

1. **Import Samples**
   - Click "Import Folder" (⌘I)
   - Select a folder with audio samples (.wav, .mp3, .aiff, etc.)
   - Wait for the scan to complete

2. **Try Features**
   - 🔍 Search for samples
   - 🎵 Double-click to play audio
   - ⭐ Click star icon to favorite
   - 🏷️ Right-click → "Add Tags..."

3. **Enable Analysis** (Optional)
   - Open Settings (⌘,)
   - Go to "Analysis" tab
   - Click "Analyze Unanalyzed Samples"
   - This detects BPM and musical key

4. **Try Drag-and-Drop**
   - Open Logic Pro
   - Drag samples from SampleVault directly into your project
   - They'll be automatically imported!

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **⌥⌘S** | Show/hide window (works globally!) |
| **⌘I** | Import folder |
| **Space** | Play/pause current sample |
| **Esc** | Stop playback |
| **⌘,** | Open settings |
| **Double-click** | Play sample |

## 🎛️ Advanced Features

### Compact Mode
- Go to Settings → General
- Enable "Compact mode"
- Window shrinks to 400x600 for minimal footprint

### Float on Top
- Go to Settings → General
- Enable "Float on top of other windows"
- SampleVault stays visible while working in Logic Pro

### Smart Folders
- Apply filters (BPM, key, category, etc.)
- Click "Save Smart Folder" in toolbar
- Access saved searches from sidebar

## 🐛 Troubleshooting

### "Failed to build"
- Make sure you have Xcode 15.0+
- Go to File → Packages → Reset Package Caches
- Try building again (⌘R)

### "Code signing error"
- In Xcode, select project in navigator
- Go to "Signing & Capabilities"
- Select your Apple ID under "Team"
- Or enable "Automatically manage signing"

### "Permission denied" when importing
- This is normal - macOS sandboxing
- Click "Import Folder" and select the folder again
- The app stores security-scoped bookmarks for persistent access

## 📦 What's Included

✅ All 6 development phases complete
✅ BPM and key detection
✅ Smart folders and recent searches
✅ Batch operations
✅ Tag management
✅ Waveform visualization
✅ Logic Pro drag-and-drop integration
✅ Global hotkeys
✅ Compact mode

Version: **1.0.0 Complete** 🎉

## 💡 Tips

- Import samples from your main sample library first
- Let analysis run overnight for large libraries (1000+ samples)
- Use smart folders to organize by BPM, key, or category
- Enable "Float on top" for easy access while producing
- Use ⌥⌘S hotkey to quickly toggle SampleVault while working

## 🆘 Need Help?

Check the full README.md for detailed documentation on all features!
