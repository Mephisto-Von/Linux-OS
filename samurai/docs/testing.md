# Samurai Linux Testing Strategy

## Test Levels

### 1. Script Smoke Tests
Run `bash tests/smoke.sh` on every change. It parses every shell script,
runs ShellCheck when available, and checks:

```bash
# Theme manager installs a real .colors file and persists the selection
samurai-theme set kuro
samurai-theme list
samurai-theme status

# AI CLI: default model and credentials (no Ollama model required)
samurai-ai --help
samurai-ai set-default llama3.2:3b
samurai-ai get-default
samurai-ai credentials set openai test-key
samurai-ai credentials get openai
samurai-ai credentials remove openai

# Gaming launcher argument handling (uses a fake steam binary)
samurai-gaming steam --foo
```

Do not run `samurai-gaming install-profile` as a smoke test: it installs packages
and modifies the system.

### 2. Build Pipeline Tests
- `bash build/build.sh --check` passes (host, tools, disk, config generation)
- `lb build` completes and the hybrid ISO appears under `dist/`
- `bash build/verify-iso.sh dist/samurai-linux-*-amd64.iso` passes: BIOS and
  UEFI boot records exist, the live kernel/initramfs/squashfs are present, and
  Calamares, Samurai branding, the installer entry, GRUB packages, `unsquashfs`,
  `rsync`, and `cryptsetup` are inside the squashfs; the Samurai CLIs and KDE
  color schemes are installed; and the live menu auto-boots after 5 seconds with
  `console=ttyS0,115200n8` on the isolinux and GRUB entries
- Checksums and GPG signature verify:
  ```bash
  cd dist
  sha256sum -c samurai-linux-*.iso.sha256
  gpg --verify samurai-linux-*.iso.sig samurai-linux-*.iso
  ```

### 3. Boot Tests (QEMU)
```bash
# Headless serial check (180 s timeout)
bash build/qemu-test.sh dist/samurai-linux-*-amd64.iso

# Interactive desktop check
bash build/qemu-test.sh dist/samurai-linux-*-amd64.iso --gui
```
Pass criteria: the serial log shows kernel/systemd boot messages. The hosted
workflow uses `QEMU_TIMEOUT=300`; the verified 2026-10-26 run reached
`sddm.service` and a `samurai login:` prompt. The VGA screenshot is captured at
120 seconds and may still show boot messages, so the serial log is authoritative.
For a GUI run, confirm that SDDM appears and the Plasma live session starts as
`samurai` with the **Install Samurai Linux** icon.

### 4. Installation Tests (Calamares integrated; automated test not yet available)
- Guided partitioning completes and the system reboots into the installed OS
- LUKS-encrypted install unlocks with the passphrase and boots
- UEFI install creates an EFI system partition and a working GRUB entry
- BIOS install writes GRUB to the disk and boots
- The installed system reaches SDDM and accepts the account created in Calamares
- First-boot setup is manual; there is no Samurai first-boot wizard

### 5. Desktop and Theme Tests
- Kuro applies: background `#111214`, crimson `#B52832`, gold `#B89A59`
- Shiro applies: background `#F5F0E6`, vermilion `#B52832`, gold `#96733B`
- Theme persists across logout/reboot
- `samurai-theme auto` switches based on time of day
- Contrast and visible focus states verified in both themes

### 6. AI Runtime Tests
- `samurai-ai chat` works with a configured local model
- Local mode works with no cloud API key present
- Cloud mode discloses external data transmission before sending
- Model router documents selection criteria and honors user overrides
- Resource limits pause inference under high system load

### 7. Gaming Tests (on declared supported configurations)
- Steam installs and launches via `samurai-gaming steam`
- Proton runs at least one Windows title
- GameMode engages (`systemctl --user status gamemoded`)
- MangoHUD overlay displays (`MANGOHUD=1 %command%`)
- Controller detected and usable

### 8. Performance Baselines
Measure and compare against documented baselines:
```
Boot time:       8-12 seconds (SSD), 30-45 seconds (HDD)
Idle memory:     400-600 MB (KDE Plasma)
CPU utilization: 2-5% at desktop
```

## Release Test Matrix
| Component | Minimum coverage |
|---|---|
| ISO boot | QEMU, 1 VM per architecture |
| Installation | Calamares guided + LUKS + one manual partition (manual verification; automated VM test pending) |
| Themes | Kuro, Shiro, auto-switch |
| AI | One local model, local-only mode |
| Gaming | Steam + Proton + GameMode + MangoHUD |
| Performance | Boot time, idle RAM, idle CPU |

## Automating Tests
- `tests/smoke.sh` runs in GitHub Actions (`.github/workflows/ci.yml`) on every push and pull request
- The `live-build` job validates `build/auto/config` in a `debian:trixie` container
- The hosted ISO workflow (`.github/workflows/build-iso-hosted.yml`) builds the image in a privileged Debian container, runs `build/verify-iso.sh`, and then runs the headless QEMU boot test. Run `40346119925` on commit `028a2ac` passed both stages and reached SDDM.
- Signed release builds and full install tests run on a self-hosted runner (`.github/workflows/build-iso.yml`)
- A full Calamares install-to-disk test is still manual; no automated UI driver exists for Calamares 3.3.14
- Defects found are logged and triaged; critical defects block release
