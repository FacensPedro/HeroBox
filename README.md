# HeroBox

HeroBox 0.1.0 is an experimental iOS/iPadOS app packaging an original Xbox native engine in one IPA. Xbox 360 and Xbox One are planned for the same IPA but are not integrated yet.

## Single-IPA status

**A working three-console IPA is not complete yet.** The original Xbox frontend (DukeX/xemu) already launches its own native shared core. XeniOS currently provides the Xbox 360 core as a separate UIKit application executable, and Utsuro statically links an Xbox One/FEX engine into a different iOS host. Those standalone app entry points cannot simply be copied into one IPA and launched as independent apps.

The consolidated executable must link the XeniOS engine as an in-process core, link the Utsuro engine and its FEX/JIT components, and coordinate their initialization and shutdown with the existing xemu runtime. It also needs one game library, renderer, input router, entitlement set and JIT/memory manager. Separate executables placed in the IPA are not a valid solution.

The **0.1.0 (build 1)** release produces one `HeroBox-0.1.0.ipa` with bundle identifier `com.facenspedro.herobox`, containing the original Xbox DukeX/xemu host and the HeroBox dashboard. It does **not** run Xbox 360 or Xbox One games. The separate experimental `scripts/build-unified.sh` rejects incomplete three-console packaging. The GitHub Actions release IPA uses an ad-hoc development signature and requires signing for device installation.

## Are Xbox operating-system files required?

| Console | Requirements |
| --- | --- |
| Original Xbox | MCPX boot ROM, Xbox-compatible flash BIOS, and a properly formatted Xbox HDD image. The original Microsoft dashboard is not required when the HDD has a compatible alternative. |
| Xbox 360 | No Xbox 360 operating system, dashboard, BIOS, or NAND image is required for regular games when using Xenia/XeniOS. |
| Xbox One | Utsuro needs a **decrypted game dump** with both `Mount/` and `EmbeddedXvd/Windows`; the latter supplies Windows-derived Xbox One userland files. New OS versions may require additional compatibility tables. There is no separate full-OS installation step. |

No proprietary Microsoft firmware, OS images, keys, or commercial games are bundled in HeroBox.

## Native engine sources

- Original Xbox: [DukeX/xemu](https://github.com/MaftyManicEMU/DukeX), including the xemu ARM64 shared core, Slirp and MoltenVK.
- Xbox 360: [XeniOS](https://github.com/xenios-jp/XeniOS), including PowerPC-to-ARM64 JIT and a native Metal renderer. The upstream iOS build remains a standalone executable until refactored.
- Xbox One: [Utsuro](https://github.com/Leviidev/Utsuro), an Xbox One Windows-userland translation layer using FEX, with a separate game library, JIT initialization and bundled per-title system files.

## Build

Swift recognition tests and packaging-contract tests run in GitHub Actions. On a macOS build host:

```sh
swift test
python3 -m unittest discover -s Tests/Packaging -p 'test_*.py'
bash scripts/build-original-xbox.sh
# Experimental three-console integration gate (still blocked):
bash scripts/build-unified.sh
```

GitHub Actions builds, verifies and uploads the original Xbox IPA; a successful main-branch build publishes release `v0.1.0`. The experimental unified command checks for the missing in-process Xbox 360 and Xbox One launchers, and remains intentionally blocked. That block does not prevent the honestly labeled original Xbox 0.1.0 release.

Xbox 360 and Xbox One standalone development scripts remain for regression testing, but no separate console-edition IPAs are published. The inspector target can build on its own; it recognizes XBE, XEX, STFS and Xbox One folder layouts, but identification is not the same as game execution.

## iPhone Duo and iPad display support

HeroBox 0.1.0 targets both iPhone and iPad device families, including the iPhone Duo outer and unfolded inner displays. The SwiftUI inspector uses the live scene geometry and horizontal size class to adapt its grid, spacing, and maximum content width. It does not hard-code an iPhone model identifier or use UIScreen.main to infer a fold state.

Portrait and landscape orientations are supported on iPhone; iPad also supports upside-down portrait. The iPad target does not require fullscreen, allowing supported iPadOS multitasking and resizable windows. The same adaptive layout is intended to handle iPhone Duo folded, unfolded, and split-view scene sizes without a device-specific app edition.

These changes improve the HeroBox SwiftUI host only. The three native emulation engines must independently handle Metal drawable resizing, changing safe areas, active window scenes, gamepad overlays, and JIT/memory lifecycle before game rendering can be considered supported in all iPhone Duo poses and iPad window modes. Validate on Xcode 27.1 Device Hub with iPhone Duo open, closed, rotated and folded, and on iPad with full-screen and resized windows.
## Credits and licensing

This work references DukeX, xemu, XeniOS and Utsuro. Combined redistribution must retain their applicable license notices and comply with platform signing requirements.
