# Primitive

Primitive is a native SwiftUI foundation for an iOS and iPadOS customization platform by Mac.Core.

## Current build

The current stage establishes the adaptive interface and the first import/preview workflow. It now includes the native worse_query source and an App Group entitlement diagnostic. The PoC is linked but is not invoked automatically; runtime access remains gated on confirming that the signed app can open its App Group container.

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


## worse_query integration

Primitive includes the Objective-C `worse_query` source from [forcequitOS/worse_query](https://github.com/forcequitOS/worse_query), licensed under GPL-3.0. The upstream license is preserved at `ThirdParty/worse_query/LICENSE`.

The app-group identifier configured for this integration is `group.com.mac.core.primitive`. The build includes the corresponding entitlement declaration, but an unsigned IPA or a successful compilation does not prove that the installation signature authorizes the entitlement. Primitive checks whether the App Group container is available before any future runtime invocation.

The PoC is not executed on launch and this integration commit does not request access to any external container. The next validation step is to install the build through the user's existing signing workflow and confirm the App Group diagnostic on-device.
