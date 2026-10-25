# Samurai Linux Testing Strategy

## Test Levels

### 1. Script Smoke Tests
Run on every change to `samurai/scripts/`:
```bash
# Theme manager
samurai-theme list
samurai-theme kuro
samurai-theme shiro
samurai-theme auto

# AI CLI (no model required for these)
samurai-ai              # usage output lists all commands
samurai-ai gpu-info
samurai-ai cpu-info
samurai-ai memory-budget
samurai-ai status

# Gaming profile
samurai-gaming install-profile
```

### 2. Build Pipeline Tests
- `debootstrap` completes without errors for the target architecture
- Chroot package installation succeeds for every selected profile
- `xorriso` produces a readable ISO (verified with `isoinfo`/`xorriso -indev ... -toc`)
- Checksums and GPG signature verify:
  ```bash
  sha256sum -c samurai.sha256
  gpg --verify samurai.iso.sig samurai.iso
  ```

### 3. Boot Tests (QEMU)
```bash
# Standard boot test
qemu-system-x86_64 -cdrom samurai.iso -m 4096 -display none -boot d

# With KVM acceleration
qemu-system-x86_64 -cdrom samurai.iso -m 4096 -enable-kvm -boot d

# Failsafe entry
qemu-system-x86_64 -cdrom samurai.iso -m 2048 -display none
```
Pass criteria: reaches the KDE Plasma desktop or installer within 120s.

### 4. Installation Tests
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
- GameMode engages (`systemctl status gamemoded`)
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
- Script smoke tests run in CI on every commit
- Boot/install tests run manually per release (see `release-process.md`)
- Defects found are logged and triaged; critical defects block release
