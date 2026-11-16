# HeroBox

HeroBox is an early-stage iOS project for original Xbox, Xbox 360, and Xbox One emulation. The base SwiftUI app is a media inspector; gameplay requires a console-specific iOS runtime edition. Each runtime edition uses the HeroBox 0.1.0 version and is packaged separately, not combined into a single emulator executable.

## Play original Xbox games

Download the HeroBox-0.1.0-original-Xbox artifact from the iOS workflow, extract the IPA, sign it and install it on your device. Open Play original Xbox, configure the MCPX ROM, flash BIOS and HDD image, import an Xbox XISO into the library, enable JIT for HeroBox, then select the game to start it. On iOS 26 and later configure StikDebug with Universal.js. The device build compiles the DukeX v1.0.2 frontend, embeds its matching xemu, Slirp and MoltenVK binaries and runs the game in the HeroBox process. The inspector-only target remains available for development. No games or console firmware are included.

## Play Xbox 360 games (XeniOS runtime)

The `HeroBox-0.1.0-Xbox360` GitHub Actions artifact contains `HeroBox-0.1.0-Xbox360.ipa` for iPhone and iPad. It includes the native ARM64 Xbox 360 emulation engine from [XeniOS](https://github.com/xenios-jp/XeniOS), which is based on Xenia Edge: PowerPC CPU recompilation, a Metal GPU backend, audio, gamepad and touch-input components, game storage, and StikDebug JIT integration. This is a **separate, complete player edition**, not an external app redirect or a nonfunctional UI mock. It uses XeniOS's native in-app library and game launcher; those screens are still upstream XeniOS UI, not the SwiftUI inspector's Xbox One-style dashboard.

Download the Actions artifact, extract the IPA, sign it for your device and install it. On iOS 26 and later, configure and verify StikDebug JIT before launching games. In the Xbox 360 player edition, import a game backup that you legally own using the built-in library and start it from there. XEX, ISO, ZAR and XContent formats are handled by the XeniOS runtime; the base HeroBox inspector only recognizes signatures and cannot launch them. Support and performance vary by game, device and signing method. HeroBox has not validated individual games on physical devices.

The runtime is pinned to XeniOS source commit `77cc1358b71ec268a7fa5792c44d87f0c09a216a` and prebuilt iOS release `release-v2.3.3-build-11940`. The build verifies the upstream IPA's SHA-256 before repackaging, recompiles the complete asset catalog with the existing HeroBox icon, stamps version `0.1.0 (1)` and bundle ID `com.facenspedro.herobox.xbox360`, and ad-hoc signs the result. It preserves the original executable and upstream license notices. The original XeniOS interface and upstream acknowledgements remain included. Final signing is required for device installation; Memory+ and JIT entitlements depend on the device and signing method.

Build it on macOS with Xcode Command Line Tools and `bash scripts/build-xbox-360.sh`. The pinned prebuilt core is used so the HeroBox CI does not need to recompile the large XeniOS codebase. This does **not** demonstrate successful game execution on a device. You can build XeniOS from the exact pinned source separately for auditing or modification. No games, console keys, or firmware are distributed.

## Media identification

| Console | Recognized input |
| --- | --- |
| Original Xbox | An executable starting with `XBEH`, or an extracted folder containing a matching `default.xbe` |
| Xbox 360 | An executable starting with `XEX2`, a valid matching `default.xex`, or an STFS container starting with `CON `, `LIVE`, or `PIRS` |
| Xbox One | A selected directory containing both `Mount/` and `EmbeddedXvd/` |

Call `try XboxMedia.identify(url)` with a local file or directory URL. The method returns a console generation for recognized inputs, returns `nil` for unknown media, and throws on access errors. Recognition checks the signature or directory layout. It does not validate an entire game, extract disc images, or confirm compatibility. The inspector also detects XDVDFS disc images (`.iso` or `.xiso`) using both volume-descriptor signatures; this alone cannot distinguish original Xbox discs from Xbox 360 discs. Compatible images are imported using the appropriate original Xbox (DukeX/xemu) or Xbox 360 (XeniOS) player edition, not the inspector-only target.

## Build and test

To build the app on macOS, install XcodeGen, run `xcodegen generate`, and open `HeroBox.xcodeproj`. Select the HeroBox scheme and a signing team for device installation.

Open `Package.swift` in Xcode 15 or later. The library targets iOS 16 or later. Run `swift test` on a Mac to execute the media recognition tests.

## Xbox One device build

On a Mac with Xcode 26, XcodeGen, CMake, ccache, and the hosted-JIT husk-fex source tree, export `HUSK_FEX_DIR` and run `bash scripts/build-xbox-one.sh`. The upstream FEX build also reads `FATHOM/build/fexcore-macos-libs/libxxhash.a` if its own build does not produce that archive. The script compiles a pinned Utsuro revision and packages the engine, Metal renderer, controller support, JIT script, and HeroBox media inspector together in `build/HeroBox-XboxOne.ipa`. The standard inspector target does not link this engine.

Sign the IPA for your device. In the runtime build, choose StikDebug in Settings and use the runtime's JIT setup so it sends its matching script and prepares executable memory. Import a decrypted Xbox One game directory containing Mount and EmbeddedXvd, then select Play in the library. Xbox 360 games use the separate XeniOS-based player edition described above. No title has been validated on a physical device in this project.

## Memory+

HeroBox targets request the increased memory limit and extended virtual addressing entitlements. The signing profile and device determine whether they take effect. The inspector shows current process memory headroom. Its StikDebug action requests attachment to the current process and reports URL delivery only.

## Credits

The Xbox One device build uses [Utsuro](https://github.com/Leviidev/Utsuro), its FEX integration, StikDebug support, and game library. The Xbox 360 player edition uses [XeniOS](https://github.com/xenios-jp/XeniOS) under its BSD-3-Clause license, with bundled acknowledgements and original source/release provenance. Original Xbox emulation uses the DukeX/xemu runtime.
