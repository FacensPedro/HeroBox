# HeroBox

HeroBox is an early-stage iOS project for original Xbox, Xbox 360, and Xbox One emulation. The iPhone and iPad app inspects files and folders selected in Files. A separate experimental device build includes the Xbox One runtime.

## Play original Xbox games

Download the HeroBox-0.1.0-original-Xbox artifact from the iOS workflow, extract the IPA, sign it and install it on your device. Open Play original Xbox, configure the MCPX ROM, flash BIOS and HDD image, import an Xbox XISO into the library, enable JIT for HeroBox, then select the game to start it. On iOS 26 and later configure StikDebug with Universal.js. The device build compiles the DukeX v1.0.2 frontend, embeds its matching xemu, Slirp and MoltenVK binaries and runs the game in the HeroBox process. The inspector-only target remains available for development. No games or console firmware are included.

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

## Xbox One device build

On a Mac with Xcode 26, XcodeGen, CMake, ccache, and the hosted-JIT husk-fex source tree, export `HUSK_FEX_DIR` and run `bash scripts/build-xbox-one.sh`. The upstream FEX build also reads `FATHOM/build/fexcore-macos-libs/libxxhash.a` if its own build does not produce that archive. The script compiles a pinned Utsuro revision and packages the engine, Metal renderer, controller support, JIT script, and HeroBox media inspector together in `build/HeroBox-XboxOne.ipa`. The standard inspector target does not link this engine.

Sign the IPA for your device. In the runtime build, choose StikDebug in Settings and use the runtime's JIT setup so it sends its matching script and prepares executable memory. Import a decrypted Xbox One game directory containing Mount and EmbeddedXvd, then select Play in the library. Xbox 360 inputs currently support inspection only. No title has been validated on a physical device in this project.

## Memory+

Both targets request the increased memory limit and extended virtual addressing entitlements. The signing profile and device determine whether they take effect. The inspector shows current process memory headroom. Its StikDebug action requests attachment to the current process and reports URL delivery only.

## Credits

The Xbox One device build uses [Utsuro](https://github.com/Leviidev/Utsuro), its FEX integration, StikDebug support, and game library.
