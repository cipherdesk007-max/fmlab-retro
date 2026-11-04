// Banco di prova del Game Emulator FMLAB (fmlab-retro/prove): risponde ai core libretro come FMLABEmulatore.m
// (stesse scelte: niente opzioni v1/v2, niente GL, variabili dalla prima scelta o fissate),
// fa girare il gioco, simula tasti e controlla immagine, suono, memoria e stato salvato.
//   banco CORE.so GIOCO [fotogrammi]
#include <dlfcn.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "libretro.h"

static enum retro_pixel_format formato = RETRO_PIXEL_FORMAT_0RGB1555;
static unsigned vw, vh, cornici, diverse; static uint64_t ultimaFirma;
static size_t campioni; static uint32_t tasti;
static char chiavi[256][96], valori[256][96]; static int nvar;
static char fk[64][96], fv[64][96]; static int nf = -1;
static void leggi_fisse(void) {
    nf = 0; const char *e = getenv("BANCO_FISSE"); if (!e) return;
    char buf[8192]; snprintf(buf, sizeof buf, "%s", e);
    for (char *t = strtok(buf, ";"); t && nf < 64; t = strtok(NULL, ";")) {
        char *u = strchr(t, '='); if (!u) continue; *u = 0;
        snprintf(fk[nf], 96, "%s", t); snprintf(fv[nf], 96, "%s", u + 1); nf++;
    }
}

static void logf_(enum retro_log_level l, const char *fmt, ...) { if (l < RETRO_LOG_WARN) return; va_list a; va_start(a, fmt); fprintf(stderr, "  [core] "); vfprintf(stderr, fmt, a); va_end(a); }
static const char *val(const char *k) {
    if (nf < 0) leggi_fisse();
    for (int i = 0; i < nf; i++) if (!strcmp(fk[i], k)) return fv[i];
    for (int i = 0; i < nvar; i++) if (!strcmp(chiavi[i], k)) return valori[i];
    return NULL;
}
static bool amb(unsigned cmd, void *data) {
    static const char *dir = "/tmp/banco-dir";
    switch (cmd & ~RETRO_ENVIRONMENT_EXPERIMENTAL) {
    case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY: case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY: *(const char **)data = dir; return true;
    case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT: { enum retro_pixel_format f = *(enum retro_pixel_format *)data; if (f > RETRO_PIXEL_FORMAT_RGB565) return false; formato = f; return true; }
    case RETRO_ENVIRONMENT_GET_LOG_INTERFACE: ((struct retro_log_callback *)data)->log = logf_; return true;
    case RETRO_ENVIRONMENT_GET_CAN_DUPE: *(bool *)data = true; return true;
    case RETRO_ENVIRONMENT_GET_INPUT_BITMASKS & ~RETRO_ENVIRONMENT_EXPERIMENTAL: return true;
    case RETRO_ENVIRONMENT_GET_LANGUAGE: *(unsigned *)data = RETRO_LANGUAGE_ITALIAN; return true;
    case RETRO_ENVIRONMENT_GET_AUDIO_VIDEO_ENABLE: if (data) *(int *)data = 3; return true;
    case RETRO_ENVIRONMENT_GET_FASTFORWARDING: if (data) *(bool *)data = false; return true;
    case RETRO_ENVIRONMENT_SET_VARIABLES:
        for (const struct retro_variable *v = data; v && v->key; v++) {
            const char *s = v->value ? strstr(v->value, "; ") : NULL; if (!s || nvar >= 256) continue;
            snprintf(chiavi[nvar], 96, "%s", v->key); snprintf(valori[nvar], 96, "%s", s + 2);
            if (getenv("BANCO_OPZ")) printf("OPZ\t%s\t%s\n", v->key, s + 2);
            char *bar = strchr(valori[nvar], '|'); if (bar) *bar = 0; nvar++;
        }
        return true;
    case RETRO_ENVIRONMENT_GET_VARIABLE: { struct retro_variable *v = data; const char *x = v && v->key ? val(v->key) : NULL; if (!x) return false; v->value = x; return true; }
    case RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE: *(bool *)data = false; return true;
    case RETRO_ENVIRONMENT_SET_GEOMETRY: case RETRO_ENVIRONMENT_SET_SYSTEM_AV_INFO:
    case RETRO_ENVIRONMENT_SET_INPUT_DESCRIPTORS: case RETRO_ENVIRONMENT_SET_CONTROLLER_INFO: case RETRO_ENVIRONMENT_SET_MEMORY_MAPS & ~RETRO_ENVIRONMENT_EXPERIMENTAL:
    case RETRO_ENVIRONMENT_SET_SUBSYSTEM_INFO: case RETRO_ENVIRONMENT_SET_SUPPORT_ACHIEVEMENTS & ~RETRO_ENVIRONMENT_EXPERIMENTAL: case RETRO_ENVIRONMENT_SET_PERFORMANCE_LEVEL:
    case RETRO_ENVIRONMENT_SET_SERIALIZATION_QUIRKS: case RETRO_ENVIRONMENT_SET_SUPPORT_NO_GAME: case RETRO_ENVIRONMENT_SET_CONTENT_INFO_OVERRIDE: case RETRO_ENVIRONMENT_SET_MESSAGE:
        return true;
    default: return false;
    }
}
static void video(const void *d, unsigned w, unsigned h, size_t pitch) {
    cornici++; if (!d) return; vw = w; vh = h;
    uint64_t f = 1469598103934665603ull; const uint8_t *p = d;
    for (unsigned y = 0; y < h; y += 7) for (unsigned x = 0; x < w * (formato == RETRO_PIXEL_FORMAT_XRGB8888 ? 4 : 2); x += 13) f = (f ^ p[y * pitch + x]) * 1099511628211ull;
    if (f != ultimaFirma) diverse++;
    ultimaFirma = f;
}
static size_t suoni(const int16_t *d, size_t n) { for (size_t i = 0; i < n * 2; i++) if (d[i]) { campioni += n; break; } return n; }
static void suono(int16_t l, int16_t r) { if (l || r) campioni++; }
static void poll_(void) {}
static int16_t stato(unsigned port, unsigned dev, unsigned idx, unsigned id) {
    if (port || dev != RETRO_DEVICE_JOYPAD) return 0;
    if (id == RETRO_DEVICE_ID_JOYPAD_MASK) return (int16_t)tasti;
    return (tasti >> id) & 1;
}

#define S(n) __typeof__(n) *p_##n = (__typeof__(n) *)dlsym(lib, #n); if (!p_##n) { printf("manca %s\n", #n); return 1; }
int main(int argc, char **argv) {
    if (argc < 3) return 2;
    int giri = argc > 3 ? atoi(argv[3]) : 900;
    void *lib = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL); if (!lib) { printf("dlopen: %s\n", dlerror()); return 1; }
    S(retro_set_environment) S(retro_init) S(retro_get_system_info)
    S(retro_set_video_refresh) S(retro_set_audio_sample) S(retro_set_audio_sample_batch)
    S(retro_set_input_poll) S(retro_set_input_state) S(retro_load_game)
    S(retro_get_system_av_info) S(retro_run) S(retro_serialize_size)
    S(retro_serialize) S(retro_unserialize) S(retro_unload_game) S(retro_deinit)
    S(retro_get_memory_data) S(retro_get_memory_size) S(retro_set_controller_port_device)
    if (system("mkdir -p /tmp/banco-dir")) {}
    p_retro_set_environment(amb); p_retro_init();
    p_retro_set_video_refresh(video); p_retro_set_audio_sample(suono); p_retro_set_audio_sample_batch(suoni); p_retro_set_input_poll(poll_); p_retro_set_input_state(stato);
    struct retro_system_info si = {0}; p_retro_get_system_info(&si);
    struct retro_game_info gi = { .path = argv[2] }; void *buf = NULL;
    if (!si.need_fullpath) { FILE *f = fopen(argv[2], "rb"); fseek(f, 0, SEEK_END); gi.size = ftell(f); rewind(f); buf = malloc(gi.size); if (fread(buf, 1, gi.size, f) != gi.size) return 1; fclose(f); gi.data = buf; }
    if (!p_retro_load_game(&gi)) { printf("FALLITO: il core non apre il gioco\n"); return 1; }
    p_retro_set_controller_port_device(0, RETRO_DEVICE_JOYPAD);
    struct retro_system_av_info av; p_retro_get_system_av_info(&av);
    struct timespec a, b; clock_gettime(CLOCK_MONOTONIC, &a);
    for (int i = 0; i < giri; i++) {
        // come un giocatore: START dopo 2 s, poi giù e A ogni tanto (i menu della 240p Test Suite cambiano schermata)
        tasti = 0;
        if (i % 120 >= 100 && i % 120 < 106) tasti |= 1u << (i < 240 ? RETRO_DEVICE_ID_JOYPAD_START : (i / 120) % 2 ? RETRO_DEVICE_ID_JOYPAD_DOWN : RETRO_DEVICE_ID_JOYPAD_A);
        p_retro_run();
    }
    clock_gettime(CLOCK_MONOTONIC, &b);
    double sec = (b.tv_sec - a.tv_sec) + (b.tv_nsec - a.tv_nsec) / 1e9;
    size_t n = p_retro_serialize_size(); void *st = malloc(n ? n : 1);
    bool ser = n && p_retro_serialize(st, n), unser = ser && p_retro_unserialize(st, n);
    printf("%-14s %-12s %ux%u fps=%.2f hz=%.0f formato=%d cornici=%u schermate-diverse=%u suono=%s stato=%zuB salva=%s carica=%s sram=%zuB veloce=%.0fx variabili=%d\n",
        si.library_name, si.library_version, vw, vh, av.timing.fps, av.timing.sample_rate, formato, cornici, diverse, campioni ? "sì" : "no",
        n, ser ? "ok" : "NO", unser ? "ok" : "NO", p_retro_get_memory_size(RETRO_MEMORY_SAVE_RAM), giri / sec / av.timing.fps, nvar);
    p_retro_unload_game(); p_retro_deinit(); dlclose(lib);
    int ok = vw && vh && diverse >= 2 && cornici >= (unsigned)giri / 2 && ser && unser;
    printf("%s\n", ok ? "OK" : "PROBLEMA");
    return ok ? 0 : 1;
}
