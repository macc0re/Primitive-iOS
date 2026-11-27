# Primitive

Primitive is a native SwiftUI foundation for an iOS and iPadOS customization platform by Mac.Clover.

## Foundation build

This initial stage establishes the adaptive interface and build pipeline. It does **not** yet include the worse_query engine or perform system modifications.

### Modules
- Gestalt Tweaks — planned MobileGestalt package manager
- Icon Studio — planned icon customization module
- Live Wallpapers — planned PosterBoard and media library
- Device Manager — planned compatibility and backup tools
- Primitive Store — planned package catalog

### Technical stack
- Swift and SwiftUI
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

Primitive 0.1.0-dev — Foundation UI.
