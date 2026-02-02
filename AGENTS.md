# Sidepiece: Agent Guide

This document provides essential context for AI agents working on the Sidepiece project.

## Project Overview
Sidepiece is a macOS utility for managing and triggering snippets/macros via global hotkeys (primarily numpad).

## Technical Architecture
- **Language**: Swift / SwiftUI
- **UI Framework**: SwiftUI for views, AppKit for window management (HUD/Status Bar).
- **Project Structure**: Managed via `XcodeGen` and `project.yml`. Do **not** commit `.xcodeproj` files.

## Critical Workflows

### 1. Project Generation
We use `XcodeGen` to manage the project file. If you modify `project.yml` or add new files:
- Run `xcodegen generate` to update the Xcode project.

### 2. Accessibility Permissions
The app uses an event tap (`CGEvent.tapCreate`) to monitor global numpad presses. This requires **Accessibility Permissions**.
- **Development Issue**: macOS frequently resets these permissions if the binary's signing or path changes.
- **Solution**: We use a fixed build path defined in `project.yml` (`./build/Debug`).
- **Reset Script**: Use `scripts/reset_permissions.sh` to clear stale TCC entries if the app stops responding to keys despite permissions being enabled.
- **Auto-Start**: `AppDelegate` has an auto-retry loop that starts the monitor as soon as permissions are granted in System Settings.

### 3. Heads-Up Display (HUD)
The HUD is implemented as a semi-transparent `NSPanel` with a high window level (`.mainMenu`).
- **Interaction**: It ignores mouse events (`ignoresMouseEvents = true`) to stay non-intrusive.
- **Aesthetics**: Uses native glassmorphism (materials) via `VisualEffectView`.
- **Idle State**: Collapses into a minimal black "dot" in the bottom-right corner when inactive.

### 4. Folder Navigation
- Users can nest macros into folders.
- Numpad keys 1-9 switch between items in the current folder.
- Key `0` or `Clear` goes back up one level (to Root).
- **Auto-Exit**: By default, the app returns to the Root macro level after 5 seconds of inactivity (configurable in Settings).

## Development Guidelines
- Always use Australian spelling in UI and documentation.
- Maintain premium aesthetics using modern SwiftUI components and subtle animations.
- Prefer `AppKit` for low-level system integration (Clipboard, Global Hotkeys) and `SwiftUI` for the user interface.
