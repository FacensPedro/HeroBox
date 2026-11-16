# HeroBox

HeroBox is an early-stage iOS project for original Xbox, Xbox 360, and Xbox One emulation. The iPhone and iPad app inspects files and folders selected in Files. Game execution is still under development.

## Media identification

| Console | Recognized input |
| --- | --- |
| Original Xbox | An executable starting with `XBEH`, or an extracted folder containing a matching `default.xbe` |
| Xbox 360 | An executable starting with `XEX2`, or an extracted folder containing a matching `default.xex` |
| Xbox One | A selected directory containing both `Mount/` and `EmbeddedXvd/` |

Call `try XboxMedia.identify(url)` with a local file or directory URL. The method returns a console generation for recognized inputs, returns `nil` for unknown media, and throws on access errors. Recognition checks the signature or directory layout. It does not validate an entire game, extract disc images, or confirm compatibility.

## Build and test

To build the app on macOS, install XcodeGen, run `xcodegen generate`, and open `HeroBox.xcodeproj`. Select the HeroBox scheme and a signing team for device installation.

Open `Package.swift` in Xcode 15 or later. The library targets iOS 16 or later. Run `swift test` on a Mac to execute the media recognition tests.

The iOS workflow runs the tests and builds the app for a generic iOS device. Triggering the workflow manually also attempts to build a separate upstream Utsuro IPA from its default branch. That artifact contains Utsuro. HeroBox does not yet bundle an emulator core.

## Runtime projects

- [Xenra](https://github.com/Yebot32/xenra) targets the original Xbox and Xbox 360.
- [XeniOS](https://github.com/xenios-jp/XeniOS) targets Xbox 360 on Apple devices.
- [Utsuro](https://github.com/Leviidev/Utsuro) targets Xbox One games on Apple devices.
