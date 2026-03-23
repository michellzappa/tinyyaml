# TinyYAML

A native macOS YAML viewer and editor. Collapsible tree on one side, syntax-highlighted source on the other. Tells you exactly where the indentation is broken.

![macOS](https://img.shields.io/badge/macOS-26%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

![TinyYAML screenshot](screenshot.png)

## Features

- **Tree preview** — browse YAML structure as a collapsible, color-coded tree
- **Syntax highlighting** — keys, strings, numbers, booleans, comments, anchors
- **Real-time validation** — friendly errors with line and column numbers
- **Click-to-jump** — click error messages to jump to the problem
- **Folder sidebar** — browse directories, favorites, and subdirectories
- **Multi-tab editing** — open multiple files in tabs with dirty-file indicators
- **Auto-save** — saves as you type with dirty-file indicators
- **Find & replace** — native macOS find bar (Cmd+F)
- **Quick open** — fuzzy file finder (Cmd+P)
- **Line numbers** — optional gutter with current line highlight
- **Word wrap** — toggle with Opt+Z
- **Font size control** — Cmd+/Cmd- to adjust, Cmd+0 to reset
- **File watcher** — reloads when files change externally
- **Export** — PDF, HTML, or copy as rich text
- **Light & dark mode** — follows system appearance
- **Open from Finder** — double-click .yaml or .yml files to open in TinyYAML
- **On-device AI** — Cmd+K to edit, transform, or ask questions (CoreML, fully offline)

## Requirements

- macOS 26.0+
- Xcode 26+ (to build)

## Build

```bash
xcodebuild clean build \
  -project TinyYAML.xcodeproj \
  -scheme TinyYAML \
  -configuration Release \
  -derivedDataPath /tmp/tinybuild/tinyyaml \
  CODE_SIGN_IDENTITY="-"

cp -R /tmp/tinybuild/tinyyaml/Build/Products/Release/TinyYAML.app /Applications/
```

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Cmd+N | New file |
| Cmd+O | Open file |
| Cmd+Shift+O | Open folder |
| Cmd+S | Save |
| Cmd+P | Quick open |
| Cmd+F | Find |
| Cmd+K | AI assistant |
| Opt+Z | Toggle word wrap |
| Opt+P | Toggle preview |
| Opt+L | Toggle line numbers |
| Cmd+= / Cmd+- | Font size |
| Cmd+0 | Reset font size |

## Tech

Built with SwiftUI, NSOutlineView, TinyKit, and [Yams](https://github.com/jpsim/Yams).

## Part of [TinySuite](https://tinysuite.app)

Native macOS micro-tools that each do one thing well.

| App | What it does |
|-----|-------------|
| [TinyMark](https://github.com/michellzappa/tinymark) | Markdown editor with live preview |
| [TinyTask](https://github.com/michellzappa/tinytask) | Plain-text task manager |
| [TinyJSON](https://github.com/michellzappa/tinyjson) | JSON viewer with collapsible tree |
| [TinyCSV](https://github.com/michellzappa/tinycsv) | Lightweight CSV/TSV table viewer |
| [TinyPDF](https://github.com/michellzappa/tinypdf) | PDF text extractor with OCR |
| [TinyLog](https://github.com/michellzappa/tinylog) | Log viewer with level filtering |
| [TinySQL](https://github.com/michellzappa/tinysql) | Native PostgreSQL browser |
| [TinyText](https://github.com/michellzappa/tinytext) | Clean plain text editor |
| **TinyYAML** | YAML viewer with tree navigation |

## License

MIT
