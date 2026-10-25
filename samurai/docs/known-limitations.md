# Samurai Linux - Known Limitations

## Build and Release
- **Bootable ISO not yet generated** - the original build environment lacked
  the resources required (see below). The full pipeline is documented in
  `build-guide.md` and `RELEASE_DESCRIPTION.md`.
- **Build host requirements**: 50 GB+ free disk (100 GB recommended), 8 GB+ RAM
  (16 GB recommended). The originating environment had ~2.3 GB free disk and
  ~174 MB free RAM, which blocks `debootstrap` and ISO assembly.
- **No Secure Boot signature** - builds are unsigned; users must sign the
  bootloader themselves or disable Secure Boot.

## AI Runtime
- **Model size limited by RAM** - larger models (12B+) need 16 GB+ system RAM
  or a compatible GPU; `samurai-ai check-compatibility` advises what will run
- **Ollama installed separately** - model management depends on Ollama, which
  is installed during first-boot setup, not baked into the live ISO
- **Cloud modes require user-provided API keys** - no bundled credentials;
  usage may incur charges and transmits data externally (disclosed at request time)
- **Speech input/output optional** - depends on Whisper/eSpeak availability

## Gaming
- **Anti-cheat limitations** - some titles (kernel-level anti-cheat) do not
  work under Proton regardless of configuration
- **NVIDIA drivers manual** - NVIDIA setup is documented but not auto-configured
- **Not all Windows games work** - Proton compatibility varies by title;
  check ProtonDB before expecting a given game to run
- **Overclocking excluded** - risky performance tweaks are optional and not
  enabled by default

## Desktop and Themes
- **Samurai icon set and wallpapers pending** - theme color schemes are
  complete; the full custom icon set, cursors, and original artwork are planned
- **Plasma Wayland quirks** - some gaming overlays (MangoHUD) work best on X11
  sessions currently

## Scope
- **Single architecture** - x86_64 only; no ARM or RISC-V builds
- **KDE Plasma only** - no alternate desktop environments offered
- **Debian Trixie base** - tied to Debian's package cadence; upstream packages
  must be packaged into the Samurai repository for inclusion
