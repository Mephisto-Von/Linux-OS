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
Pass criteria: the serial log shows kernel/systemd boot messages, and the GUI run
reaches the KDE Plasma live session as user `samurai` within 120s. The current
ISO has no installer.

### 4. Installation Tests (target design; not yet available)
- Guided partitioning completes and system reboots into installed OS
- LUKS-encrypted install unlocks with passphrase and boots
- Each profile (minimal, developer, gaming, AI/dev, full) installs cleanly
- First-boot wizard completes all 10 steps

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
| Installation | Guided + LUKS + one manual partition |
| Themes | Kuro, Shiro, auto-switch |
| AI | One local model, local-only mode |
| Gaming | Steam + Proton + GameMode + MangoHUD |
| Performance | Boot time, idle RAM, idle CPU |

## Automating Tests
- `tests/smoke.sh` runs in GitHub Actions (`.github/workflows/ci.yml`) on every push and pull request
- The `live-build` job validates `build/auto/config` in a `debian:trixie` container
- Boot/install tests run manually or on a self-hosted runner (`.github/workflows/build-iso.yml`)
- Defects found are logged and triaged; critical defects block release
