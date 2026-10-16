# Contributing

## Setup

- macOS 13 or later
- Xcode 15
- XcodeGen

```bash
scripts/build_and_run.sh
```

The Xcode project is generated from `project.yml`. Don't commit `Sidepiece.xcodeproj`.

## Tests

```bash
xcodebuild test -project Sidepiece.xcodeproj -scheme Sidepiece -destination 'platform=macOS'
```

## Style

- Australian spelling in UI text and docs
- Follow the Swift API Design Guidelines
- Keep functions small and focused
