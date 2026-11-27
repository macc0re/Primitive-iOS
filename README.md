# Primitive

Primitive is a native SwiftUI foundation for an iOS and iPadOS customization platform by Mac.Core.

## Current build

The current stage establishes the adaptive interface and the first import/preview workflow. It does **not** yet include the worse_query engine or perform system modifications.

### Modules
- Gestalt Tweaks — planned MobileGestalt package manager
- Icon Studio — planned icon customization module
- Passcode Studio — imports and previews Cowabunga/Nugget `.passthm` theme archives
- Live Wallpapers — planned PosterBoard and media library
- Device Manager — planned compatibility and backup tools
- Primitive Store — planned package catalog

### Passcode Studio scope
- Imports `.passthm` and ZIP theme archives
- Extracts keypad image assets in memory for preview
- Recognizes digit artwork and reports missing keys
- Keeps imported archives in the app's Documents directory
- Does not apply themes to the device yet

### Technical stack
- Swift and SwiftUI
- ZIPFoundation for archive inspection
- iPhone and iPad adaptive navigation
- XcodeGen project generation
- GitHub Actions on macOS 15

## Build

Install Xcode and XcodeGen, then run:

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project Primitive.xcodeproj -scheme Primitive -sdk iphoneos -configuration Release CODE_SIGNING_ALLOWED=NO build
```

The GitHub Actions workflow packages an **unsigned IPA** for build validation. It is not directly installable until signed with an appropriate provisioning profile.

## Project status

Primitive 0.1.0-dev — Passcode Studio import and preview prototype.
