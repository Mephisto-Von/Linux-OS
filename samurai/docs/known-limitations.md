# Samurai Linux - Known Limitations

## Build and Release
- **Hosted ISO build works** - `.github/workflows/build-iso-hosted.yml` builds
  the ISO on an ephemeral GitHub runner inside a privileged Debian trixie
  container. Local builds still require a Linux host with 50 GB+ free disk (100
  GB recommended), 4 GB+ RAM (8 GB recommended), and root for `chroot`.
- **Interactive installation is not yet end-to-end tested in CI** - the ISO
  builds, passes content verification, and boots to SDDM in QEMU (run
  `40346119925`). No automated test clicks through Calamares to install to a
  virtual disk, so partitioning, bootloader installation, and first boot on real
  hardware should be treated as unverified.
- **Bootloader and console branding remains Debian** - the isolinux/GRUB splash
  and the live `/etc/issue` use Debian's defaults. Calamares and the desktop use
  Samurai branding.
- **No first-boot wizard** - the installed system boots to SDDM; theme, AI, and
  gaming setup are manual commands after login.
- **Installed system is not Secure Boot signed** - the live ISO uses Debian's
  signed UEFI shim, but Calamares installs unsigned GRUB by default. Disable
  Secure Boot after installation or sign the bootloader with your own keys.
- **Artifact retention** - hosted ISO artifacts expire after 7 days.

## AI Runtime
- **Model size limited by RAM** - larger models (12B+) need 16 GB+ system RAM
  or a compatible GPU; `samurai-ai check-compatibility` advises what will run
- **Ollama installed separately** - model management depends on Ollama, which is
  not baked into the live ISO; install it after first boot (there is no setup wizard)
- **Cloud chat not implemented** - the CLI stores provider credentials, but chat
  currently targets local Ollama only; no data is sent to cloud providers
- **Speech input/output not implemented** - these remain planned features

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
