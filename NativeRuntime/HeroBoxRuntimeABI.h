#ifndef HEROBOX_RUNTIME_ABI_H
#define HEROBOX_RUNTIME_ABI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Both native adapters must run in the already-started HeroBox process.
// They MUST NOT call UIApplicationMain, launch another process, or load an
// independently signed executable as an iOS app.
#define HEROBOX_RUNTIME_ABI_VERSION 1u

typedef enum HeroBoxRuntimeEvent {
    HEROBOX_EVENT_STARTING = 1,
    HEROBOX_EVENT_FIRST_FRAME = 2,
    HEROBOX_EVENT_STOPPED = 3,
    HEROBOX_EVENT_ERROR = 4
} HeroBoxRuntimeEvent;

typedef void (*HeroBoxRuntimeReport)(
    HeroBoxRuntimeEvent event,
    int32_t value,
    const char *message,
    void *context
);

typedef struct HeroBoxLaunchConfig {
    uint32_t abi_version;
    uint32_t size;
    const char *game_path;
    const char *writable_data_path;
    void *metal_layer;
    HeroBoxRuntimeReport report;
    void *context;
} HeroBoxLaunchConfig;

// Run one title synchronously on the caller-designated emulation thread.
// Returns 0 for a clean guest exit, or a nonzero native runtime error.
// Export these functions only when the full original source core is linked.
int32_t herobox_xenia_launch(const HeroBoxLaunchConfig *config);
int32_t herobox_utsuro_launch(const HeroBoxLaunchConfig *config);

// Stop requests must be cooperative and release the core's GPU/input/JIT
// session without terminating the HeroBox application process.
void herobox_xenia_request_stop(void);
void herobox_utsuro_request_stop(void);

#ifdef __cplusplus
}
#endif

#endif // HEROBOX_RUNTIME_ABI_H
