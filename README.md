# Sidepiece

> Your numpad's new best friend 🎹

A macOS menu bar utility that transforms your numpad into a powerful clipboard shortcut system. Press a numpad key, get your pre-configured text snippet copied to your clipboard—ready to paste.

## Features

- **Menu Bar App** — Lives quietly in your top menu bar, always ready
- **Numpad Shortcuts** — Map any numpad key (0-9, +, -, *, /, =, Enter, Clear) to a text snippet
- **F-Key Support** — Extend your shortcuts with F1-F12 keys
- **Multiple Profiles** — Switch between different snippet sets for work, personal, or project-specific use
- **Offline First** — All data stored locally. No accounts, no cloud, no tracking
- **Fast & Lightweight** — Native Swift app with minimal resource usage

## Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permissions (for global hotkey detection)

## Installation

### From Releases
1. Download the latest `.dmg` from [Releases](https://github.com/kristiant/sidepiece/releases)
2. Drag **Sidepiece** to your Applications folder
3. Launch and grant Accessibility permissions when prompted

### Build from Source
```bash
# Clone the repository
git clone https://github.com/kristiant/sidepiece.git
cd sidepiece

# Open in Xcode
open Sidepiece.xcodeproj

# Build and run (⌘R)
```

## Usage

1. **Launch Sidepiece** — The icon appears in your menu bar
2. **Configure Snippets** — Click the menu bar icon → Preferences
3. **Bind Keys** — Assign your frequently used text to numpad keys
4. **Use It** — Press a numpad key anywhere, your snippet is copied!
5. **Paste** — ⌘V to paste your snippet

### Example Use Cases

- **Email templates** — Quick responses bound to Num1-Num5
- **Code snippets** — Console.log, import statements, boilerplate
- **AI prompts** — Your favourite ChatGPT/Claude prompts at a keypress
- **Contact info** — Email, phone, address on demand
- **Signatures** — Different signatures for different contexts

## Permissions

Sidepiece requires **Accessibility** permissions to detect global key presses:

1. System Settings → Privacy & Security → Accessibility
2. Enable Sidepiece in the list

Without this permission, the app cannot detect numpad presses when other apps are in focus.

## Data Storage

All data is stored locally in:
```
~/Library/Application Support/Sidepiece/
```

Your snippets never leave your machine.

## Roadmap

- [x] Core numpad key detection
- [x] Basic snippet management
- [ ] Multiple profiles
- [ ] Snippet categories & tags
- [ ] Template variables (date, time, clipboard contents)
- [ ] Application-specific auto-switching
- [ ] Import/export configurations
- [ ] Keyboard shortcut overlay

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a PR.

## Licence

[MIT](LICENCE)

---

Made with ☕ in Melbourne
