# HeroBox

HeroBox 0.1.1 is an experimental iOS/iPadOS emulator project targeting **one signed IPA** with original Xbox, Xbox 360, and Xbox One cores.

## Single-IPA status

**A working three-console IPA is not complete yet.** The original Xbox frontend (DukeX/xemu) already launches its own native shared core. XeniOS currently provides the Xbox 360 core as a separate UIKit application executable, and Utsuro statically links an Xbox One/FEX engine into a different iOS host. Those standalone app entry points cannot simply be copied into one IPA and launched as independent apps.

The consolidated executable must link the XeniOS engine as an in-process core, link the Utsuro engine and its FEX/JIT components, and coordinate their initialization and shutdown with the existing xemu runtime. It also needs one game library, renderer, input router, entitlement set and JIT/memory manager. Separate executables placed in the IPA are not a valid solution.

All release version settings have been moved to **0.1.1 (build 2)**. The only intended release artifact is `HeroBox-0.1.1.ipa` with bundle identifier `com.facenspedro.herobox`. The unified build script deliberately rejects the current original-Xbox-only application until genuine Xbox 360 and Xbox One native adapters exist, so no false three-console IPA is published.

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
bash scripts/build-unified.sh
```

The last command compiles the original Xbox host, then calls `scripts/verify_unified.py` to check for an in-process Xbox 360 native launcher and an in-process Xbox One native launcher. Both are **still missing**. Until they are implemented and gameplay is verified, the command fails without releasing an IPA. This is an intentional safety check, not a successful universal emulator build.

The separate Xbox development scripts remain available for regression testing, but the workflow no longer publishes one artifact per console. The inspector target can build on its own; it recognizes XBE, XEX, STFS and Xbox One folder layouts, but identification is not the same as game execution.

## Credits and licensing

This work references DukeX, xemu, XeniOS and Utsuro. Combined redistribution must retain their applicable license notices and comply with platform signing requirements.
