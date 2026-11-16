# HeroBox 0.1.0

Initial experimental iPhone/iPad release with the **original Xbox** DukeX/xemu native ARM64 runtime. The release includes a single IPA: HeroBox-0.1.0.ipa (build 1, bundle ID com.facenspedro.herobox).

## Included
- Original Xbox xemu core, Slirp network library, and MoltenVK.
- HeroBox console-style dashboard, media inspector, Memory+ status, and StikDebug shortcut.
- Adaptive interface for iPhone (including different iPhone Duo screen sizes) and iPad.
- Original Xbox library and controller support inherited from the DukeX host.

## Limitations and installation
- **Xbox 360 and Xbox One games do not run in this version.** XeniOS and Utsuro are not integrated into this IPA; the corresponding dashboard options are informational.
- Original Xbox games require a user-supplied MCPX ROM, compatible Xbox BIOS, and formatted HDD image. No proprietary Xbox firmware, OS, keys, or games are bundled.
- This IPA uses **ad-hoc signing**. It must be signed with a suitable identity before installing on an iOS device.
- Successful archive compilation does not confirm that a particular game boots, renders frames, or runs correctly on a real device.
- iPhone Duo folding, iPad window resizing, JIT lifecycle, and controller/gameplay behavior require physical device validation.

The code and third-party licensing information are available in the repository.
