# Native runtime integration contract

## Single-process requirement

HeroBox 0.1.1 targets a single iOS application executable. Each console core must use an in-process entry point. An embedded .ipa, .app, or standalone Mach-O executable cannot be treated as an integrated launcher.

## Original Xbox

The DukeX host already supplies xemu launch and controller/renderer setup with libxemu-ios-core.dylib. It requires MCPX ROM, flash BIOS, and a valid HDD image. The host is currently the base of the unified development build.

## Xbox 360

The pinned XeniOS iOS release is currently a complete UIApplicationMain-based app, not an embeddable library. Refactor XeniOS's app entry and core initialization behind herobox_xenia_launch, preserving the ARM64 JIT, Metal GPU, audio, storage, Xbox 360 kernel HLE and controller handlers. Do not attempt to dlopen the existing Mach-O executable as a dylib. Ensure the runtime respects the host's Metal layer, scene and single active emulation session.

## Xbox One

Utsuro already builds a libutsuro-core.a static library, but the original Utsuro SwiftUI host currently manages the FEX JIT setup, window scene, game metadata and per-title Windows userland. Link the core and FEX dependencies into the HeroBox host and implement herobox_utsuro_launch with correct JIT prewarming, game import, and lifecycle management. Game dumps require both Mount and EmbeddedXvd/Windows. Ensure the Utsuro launcher does not establish its own UIApplicationMain.

## ABI

The public integration surface is NativeRuntime/HeroBoxRuntimeABI.h. Each launcher receives a versioned HeroBoxLaunchConfig with the game path, writable data root, Metal layer, and a status callback. It reports starting, first-frame, stopped, or error events. Both launchers need cooperative stop implementations. Functions must be backed by real emulation code, not placeholder return values.

## Release verification

The strict verifier checks metadata and native entry points before allowing a single IPA to be uploaded. It does not prove device runtime correctness. Device acceptance requires at least one known legal test title for each generation, measured first-frame render, controller functionality, a clear failure log, repeatable exit/relaunch, and proof that JIT and memory permissions are active.

The unified build is blocked until both missing adapters and game dispatch are implemented and verified. The former separate IPA scripts remain internal development tools.
