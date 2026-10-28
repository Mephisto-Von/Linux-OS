# Building Samurai Linux

The ISO is assembled with Debian's [`live-build`](https://wiki.debian.org/Projects/DebianLive/). This replaces the hand-written `debootstrap` + `xorriso` steps from the original documentation, which could not produce a bootable image.

## Host requirements

| Resource | Minimum | Recommended |
|---|---|---|
| OS | Debian 13 or Debian 12 | Debian 13 |
| Architecture | x86_64 | x86_64 |
| Free disk | 50 GiB | 100 GiB |
| RAM | 4 GiB | 8 GiB |
| CPU | 2 cores | 4+ cores |

Install the tools on the build host:

```bash
sudo apt-get update
sudo apt-get install -y live-build debootstrap xorriso squashfs-tools gnupg
```

> Build on a real Linux filesystem (ext4/xfs/btrfs). Do not build inside `/mnt/c` or `/mnt/d` under WSL: `chroot` and package maintainer scripts need Unix permissions and device nodes.

## Build

```bash
# From the repository root
sudo bash build/build.sh
```

The script:

1. verifies the host (Linux, x86_64, tools, disk, RAM)
2. copies `samurai/scripts/` and `samurai/themes/` into the live-build include tree
3. runs `auto/config`
4. runs `lb clean --purge` and `lb build`
5. copies the ISO to `dist/` and writes a SHA-256 checksum

Output:

```
dist/samurai-linux-YYYY.MM.DD-amd64.iso
dist/samurai-linux-YYYY.MM.DD-amd64.iso.sha256
```

Useful modes:

```bash
bash build/build.sh --check     # validate host and generate config only
sudo bash build/build.sh --no-clean
sudo bash build/build.sh --clean
```

## Signing

```bash
sudo -E SAMURAI_SIGN_KEY="your-gpg-key-id" bash build/build.sh
```

This creates an armored detached signature (`*.iso.sig`) next to the ISO. Verify it with:

```bash
gpg --verify dist/*.iso.sig dist/*.iso
(cd dist && sha256sum -c ./*.iso.sha256)
```

## Verify the ISO

After a build, verify the live rootfs and installer wiring before booting:

```bash
bash build/verify-iso.sh dist/samurai-linux-*-amd64.iso
```

The script checks the BIOS/UEFI boot records, extracts `/live/vmlinuz`,
`/live/initrd.img`, and `/live/filesystem.squashfs` from the ISO, then verifies
inside the squashfs:

- Calamares and `calamares-settings-debian` are installed
- `branding: samurai` is selected and the Samurai branding assets exist
- the menu entry is named **Install Samurai Linux**
- `grub-pc-bin`, `grub-efi-amd64-bin`, and `efibootmgr` are present for the
  installer's bootloader step
- Calamares runtime tools are present: `unsquashfs` (from `squashfs-tools`),
  `rsync`, and `cryptsetup`
- the Samurai CLIs and Kuro/Shiro KDE color schemes are installed
- the live boot menu auto-boots after 5 seconds and passes
  `console=ttyS0,115200n8` to the kernel on both the isolinux and GRUB entries

## Boot test

```bash
# Headless: writes serial output and exits after 180 seconds
bash build/qemu-test.sh dist/samurai-linux-*-amd64.iso

# Interactive
bash build/qemu-test.sh dist/samurai-linux-*-amd64.iso --gui
```

The headless run checks the serial log for kernel/systemd boot signs. The hosted
workflow raises the timeout to 300 seconds; the verified run reached
`sddm.service` and a `samurai login:` prompt. The VGA screenshot is captured at
120 seconds and may still show boot messages, so the serial log is authoritative.
For a visual check, use `--gui` and confirm that SDDM/KDE Plasma starts.

### Verified build

The hosted run [40346119925](https://github.com/Mephisto-Von/Linux-OS/actions/runs/40346119925)
built commit `028a2ac` and passed every stage:

| Item | Value |
|---|---|
| ISO | `samurai-linux-2026.10.26-amd64.iso` |
| Size | 2,547,646,464 bytes (2.37 GiB) |
| SHA-256 | `811ae8b19f4f0296dc485014f5772c587a7e531f6269553e30b0bd4caf9b7555` |
| Content verification | Passed |
| QEMU boot test | Passed; serial log reached `sddm.service` and `samurai login:` |
| Artifact | `samurai-linux-iso` (expires 2026-11-02) |

The interactive Calamares installation itself is still not automated; see
[`../samurai/docs/known-limitations.md`](../samurai/docs/known-limitations.md).

## What the ISO contains

- Debian 13 (Trixie), KDE Plasma, SDDM, Firefox, common KDE applications
- Developer basics: Git, GCC/Clang via `build-essential`, CMake, Ninja, Python 3
- `samurai-ai`, `samurai-theme`, and `samurai-gaming` in `/usr/local/bin`
- Kuro and Shiro KDE color schemes in `/usr/share/color-schemes`
- 22 Samurai wallpapers in `/usr/share/backgrounds/samurai`; `samurai-theme`
  applies the theme's wallpaper (`kuro.jpg` / `shiro.jpg`) on theme switch
- Kuro applied for new users; the theme autostart entry restores the last selection
  and applies the matching wallpaper
- Calamares installer with Samurai branding, launched from the live desktop or
  the application menu as **Install Samurai Linux**
- Calamares runtime tools (`squashfs-tools`/`unsquashfs`, `rsync`, `cryptsetup`)
  and optional filesystem tools (`btrfs-progs`, `xfsprogs`, `f2fs-tools`,
  `ntfs-3g`)
- GRUB BIOS/UEFI installer packages (`grub-pc-bin`, `grub-efi-amd64-bin`,
  `efibootmgr`, `dosfstools`, `mtools`) and `os-prober` so Calamares can install
  a bootloader and detect existing systems
- A 5-second boot-menu timeout so the live image boots unattended on headless
  machines and servers; the kernel also logs to `ttyS0` for diagnostics
- No Steam, Ollama, or first-boot setup wizard - install Steam/Ollama after
  boot; the installed system inherits the live rootfs

## Customisation

| Path | Purpose |
|---|---|
| `build/auto/config` | `lb config` options (distribution, archive areas, boot parameters) |
| `build/config/package-lists/*.list.chroot` | Packages installed in the chroot |
| `build/config/hooks/normal/*.hook.chroot` | Chroot setup (permissions, color schemes, cleanup) |
| `build/config/includes.chroot/` | Files copied verbatim into the ISO |
| `samurai/scripts/` | Source of truth for the three CLIs |
| `samurai/themes/` | Source of truth for the KDE `.colors` schemes |
| `Samurai Walls/` | Source art for the wallpapers and installer slide |
| `build/make-wallpapers.py` | Generates 1920x1080 wallpapers + the Calamares slide from that art |

The generated copies under `build/config/includes.chroot/usr/local/bin/` and `.../usr/share/samurai/themes/` are ignored by Git; `build.sh` recreates them on every run. The generated wallpapers under `.../usr/share/backgrounds/samurai/` and `.../etc/calamares/branding/samurai/slide1.png` **are** committed, so ISO builds do not need Pillow; rerun `python3 build/make-wallpapers.py` after changing the source art.

## CI

- `.github/workflows/ci.yml` runs ShellCheck, Python syntax checks, and `tests/smoke.sh` in a `debian:trixie` container.
- `.github/workflows/build-iso-hosted.yml` builds the ISO on an ephemeral GitHub-hosted runner inside a privileged Debian `trixie` container, verifies the ISO contents, boot-tests it in QEMU, then drives the real Calamares installer to a virtual disk (`build/install-test.py`) and boots the installed system.
- `.github/workflows/install-test.yml` runs the same install test against any earlier build's ISO artifact (dispatch it with a `run_id`, or push a change to the install harness).
- `.github/workflows/build-iso.yml` builds the ISO on a self-hosted runner labelled `samurai-builder`. The runner needs the tools above, 50+ GiB free disk, and `sudo`; use it for signed release builds.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `lb: command not found` | Install `live-build` |
| `Need at least 50 GiB free` | Free disk space or set `SAMURAI_MIN_DISK_GB` (not recommended below 50) |
| `steam-installer` missing after boot | Enable `contrib` in the installed system and run `sudo apt-get update` |
| Scripts have CRLF line endings | Re-clone inside Linux; `.gitattributes` now forces LF |
| Build fails inside WSL `/mnt/*` | Move the repo to the WSL ext4 filesystem |
