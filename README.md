# VideoBrowser

A lightweight, feature-rich macOS video player designed for efficiently browsing and managing video collections from local folders.

## Overview

VideoBrowser is a native macOS application built with SwiftUI that provides a streamlined interface for playing, organizing, and managing videos. With its intuitive keyboard-driven workflow and powerful file management capabilities, it's perfect for reviewing video collections, organizing media libraries, or quickly previewing video files.

## Features

### Video Playback
- **Native Performance** - Built on AVFoundation/AVKit for smooth, efficient playback
- **Multiple Format Support** - MP4, MOV, M4V, 3GP
- **Custom Controls** - Play/pause, seek forward/backward, mute/unmute
- **Configurable Seek Times** - Adjust seek intervals from 1-60 seconds (default: 10s)
- **Flexible Playback Options** - Choose what happens when a video ends:
  - Stop playback
  - Replay current video
  - Automatically play next video

### Browsing & Navigation
- **Folder-Based Browsing** - Scan and play all videos from any folder
- **Multiple Sort Options**:
  - File Name
  - File Path
  - Size (Smallest First)
  - Size (Largest First)
  - Random
- **Easy Navigation** - Move between videos with keyboard shortcuts
- **Random Selection** - Jump to a random video in your collection

### File Management
- **Move to Folder** - Quickly relocate videos to a configured destination
- **Delete to Trash** - Remove unwanted videos with a single keypress
- **Error Handling** - Comprehensive validation and user-friendly error messages
- **Persistent Settings** - All preferences automatically saved

### User Experience
- **Comprehensive Keyboard Shortcuts** - Control everything without touching the mouse
- **Menu Bar Integration** - Quick access to all features
- **Smart Window Behavior** - Auto-pause on minimize and window close
- **Focus-Based Playback** - Optional pause when app loses focus
- **Settings Panel** - Centralized configuration with visual reference guide

## Requirements

- macOS 11.0+ (Big Sur or later)
- Xcode 13.0+ (for building from source)

## Installation

### Option 1: Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/VideoBrowser.git
   cd VideoBrowser
   ```

2. Open the project in Xcode:
   ```bash
   open vb2.xcodeproj
   ```

3. Build and run (⌘R) or archive for distribution (Product → Archive)

### Option 2: Download Release

Download the latest `.app` bundle from the [Releases](https://github.com/yourusername/VideoBrowser/releases) page.

## Usage

### Getting Started

1. **Launch** the application
2. **Open a folder** containing videos:
   - Press `⌘O` or use File → Open Folder
3. **Navigate** through videos using arrow keys or the on-screen controls
4. **Customize** settings by pressing `⌘⇧S`

### Keyboard Shortcuts

#### File Operations
| Shortcut | Action |
|----------|--------|
| `⌘O` | Open folder |
| `M` | Move current video to configured folder |
| `Delete` | Move current video to trash |

#### Playback Control
| Shortcut | Action |
|----------|--------|
| `Space` | Play/Pause |
| `,` | Seek backward |
| `.` | Seek forward |
| `←` | Previous video |
| `→` | Next video |
| `R` | Random video |

#### View & Settings
| Shortcut | Action |
|----------|--------|
| `⌘⇧S` | Open Settings |
| `⌘1` | Sort by File Name |
| `⌘2` | Sort by File Path |
| `⌘3` | Sort by Size (Smallest First) |
| `⌘4` | Sort by Size (Largest First) |
| `⌘5` | Sort Randomly |

#### Menu Options
| Shortcut | Action |
|----------|--------|
| `⌘S` | Set playback end to Stop |
| `⌘L` | Set playback end to Replay (Loop) |
| `⌘N` | Set playback end to Next |

### Settings

Access settings via `⌘⇧S` to configure:

- **Seek Times** - Customize forward/backward seek intervals (1-60 seconds)
- **Move Destination** - Set the target folder for moved videos
- **Pause Behavior** - Control auto-pause when app loses focus
- **Resume Behavior** - Control auto-resume when app regains focus

## Supported Video Formats

- MP4 (`.mp4`)
- QuickTime Movie (`.mov`)
- MPEG-4 Video (`.m4v`)
- 3GPP (`.3gp`)

## Architecture

VideoBrowser follows a clean MVVM (Model-View-ViewModel) architecture:

### Project Structure
```
vb2/
├── vb2App.swift                 # App entry point and menu configuration
├── VideoPlayerView.swift        # Main UI with keyboard handling
├── VideoPlayerViewModel.swift   # Business logic and state management
├── VideoPlayerSubviews.swift    # Reusable UI components
├── CustomVideoPlayer.swift      # AVPlayer wrapper
├── SettingsView.swift           # Settings interface
├── Models.swift                 # Data models and enums
├── ErrorTypes.swift             # Custom error definitions
├── ValidationHelper.swift       # Input validation and security
└── Logger.swift                 # Logging system
```

### Key Components

- **VideoPlayerViewModel** - Central state management for playback and file operations
- **CustomVideoPlayer** - SwiftUI wrapper around AVPlayerLayer for video rendering
- **ValidationHelper** - Security-focused input validation and file access checks
- **ErrorTypes** - User-friendly error messages with recovery suggestions

### Technologies

- **SwiftUI** - Modern declarative UI framework
- **AVFoundation/AVKit** - Video playback engine
- **Combine** - Reactive state management
- **AppKit** - Native macOS integration
- **os.log** - Unified logging system

## Testing

VideoBrowser includes comprehensive test coverage:

- **Unit Tests** - Business logic and ViewModel testing (~80% coverage)
- **UI Tests** - User interaction and interface testing

### Running Tests

**In Xcode:**
```
Product → Test (⌘U)
```

**Command Line:**
```bash
xcodebuild test -scheme vb2 -destination 'platform=macOS'
```

For detailed testing documentation, see [vb2UITests/test-readme.md](vb2UITests/test-readme.md).

## Development

### Code Quality

- **No External Dependencies** - Pure Swift using only Apple frameworks
- **Comprehensive Error Handling** - Detailed error messages with recovery suggestions
- **Input Validation** - Security-focused file and path validation
- **Logging** - Categorized logging for debugging and monitoring
- **Documentation** - Well-documented code with clear separation of concerns

### Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- Code follows Swift best practices and conventions
- New features include appropriate tests
- UI changes maintain the existing design language
- Documentation is updated as needed

## Troubleshooting

### Videos Not Playing
- Ensure the video format is supported (MP4, MOV, M4V, 3GP)
- Check that the file isn't corrupted
- Verify you have read permissions for the folder

### Folder Won't Open
- Ensure you have read permissions for the folder
- Check that the folder contains supported video files
- Review error messages for specific issues

### Move/Delete Not Working
- Verify you have write permissions for the destination folder
- Ensure the file isn't in use by another application
- Check available disk space

## License

[Add your license here - e.g., MIT, Apache 2.0, GPL, etc.]

## Author

Created by Claude Wilder

## Acknowledgments

Built with Apple's native frameworks:
- SwiftUI for the user interface
- AVFoundation for video playback
- AppKit for macOS integration

---

**Note:** VideoBrowser is designed specifically for macOS and requires macOS 11.0 (Big Sur) or later.
