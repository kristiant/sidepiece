# Sidepiece

A macOS menu bar app that turns your numpad into a snippet and shortcut pad.

## Features

- Bind numpad keys, F1 to F19, Page Up/Down, End and Delete to actions
- Actions:
  - paste a snippet
  - open a folder of snippets
  - switch or cycle profiles
  - launch an app
  - run a shell command
  - window functions (cycle windows, App Exposé, Mission Control)
- Folders of snippets, navigated with keys 1 to 9 and 0 or Clear to go back
- On-screen HUD with a peek panel. While it is open, the number row works too, for keyboards without a numpad
- Multiple profiles
- Import and export everything as JSON
- All data stays local in `~/Library/Application Support/Sidepiece/`

## Requirements

- macOS 13 or later
- Accessibility access, so Sidepiece can see key presses in other apps

## Build

Needs Xcode 15 and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
scripts/build_and_run.sh
```

Then enable Sidepiece in System Settings > Privacy & Security > Accessibility. If key presses stop working after a rebuild, run `scripts/reset_permissions.sh` and grant access again.

## Licence

[MIT](LICENCE)
