# Samurai Linux

A Debian-based operating system combining AI-assisted computing, software development,
cybersecurity, gaming, daily desktop productivity, privacy, and high performance.

- **Base**: Debian Stable (Trixie)
- **Desktop**: KDE Plasma
- **Themes**: Kuro (Dark, `#111214`) and Shiro (Light, `#F5F0E6`) with a Japanese
  Samurai-inspired design — brushstroke artwork, waves, mountains, moonlight,
  lacquered black surfaces, crimson and gold accents.

## Repository Layout

```
.
├── README.md                    - This file
├── LICENSE                      - Project license
├── RELEASE_DESCRIPTION.md       - Build status + 7-step ISO continuation pipeline
├── samurai/
│   ├── README.md                - Edition overview and quick links
│   ├── docs/
│   │   ├── architecture.md      - Full system architecture specification
│   │   └── build-guide.md       - 12-step reproducible build pipeline
│   ├── configs/                 - Configuration documentation (AI, gaming, themes, ...)
│   ├── scripts/                 - System scripts installed into the rootfs
│   ├── themes/                  - Kuro / Shiro color schemes
│   ├── iso/                     - ISO assembly directory (populated at build time)
│   ├── packages/                - Custom .deb build output
│   └── templates/               - Template files for installation
└── scripts/
    ├── analyze-iso.sh           - Analyze a built ISO with REA
    ├── post-build-workflow.sh   - Post-build workflow: REA analysis + Heretic
    └── use-heretic.py           - Heretic model decensoring wrapper
```

## Quick Start

### Themes
```bash
samurai-theme kuro     # Apply dark theme
samurai-theme shiro     # Apply light theme
samurai-theme auto      # Time-of-day automatic switching
samurai-theme list      # List available themes
```

### AI Assistant
```bash
samurai-ai chat "Hello"           # Chat with the local model
samurai-ai gpu-info               # GPU detection
samurai-ai cpu-info               # CPU detection
samurai-ai memory-budget          # Memory status
samurai-ai install-model <id>     # Pull a model via Ollama
samurai-ai list-models            # List available models
samurai-ai set-default <model>    # Set the default model
samurai-ai status                 # Inference status
samurai-ai check-compatibility    # Model/hardware compatibility check
samurai-ai credentials get|set|remove   # Secure credential storage
```

### Gaming
```bash
samurai-gaming install-profile   # Install Steam, Proton, GameMode, MangoHUD
samurai-gaming steam             # Launch Steam with MangoHUD
samurai-gaming lutris            # Launch Lutris with MangoHUD
```

## Building the ISO

The full pipeline is documented in:

1. [`samurai/docs/build-guide.md`](samurai/docs/build-guide.md) — the 12-step
   reproducible build (debootstrap → KDE Plasma + Samurai theming → xorriso →
   checksums → QEMU boot tests → release signing)
2. [`RELEASE_DESCRIPTION.md`](RELEASE_DESCRIPTION.md) — condensed 7-step
   continuation checklist with acceptance criteria

### Build host requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| Free disk | 50 GB | 100 GB |
| RAM | 8 GB | 16 GB |
| Architecture | x86_64 | x86_64 |
| Tools | `debootstrap`, `xorriso`, `gnupg`, `dpkg-dev` | + `sbuild`, QEMU |

### Pipeline overview

```bash
# 1. Verify the host
df -h / && free -h && uname -m && which debootstrap xorriso

# 2. Bootstrap the Debian base
debootstrap --arch=x86_64 trixie /samurai/rootfs http://deb.debian.org/debian/

# 3. Integrate KDE Plasma + Samurai configuration
chroot /samurai/rootfs apt-get install -y kde-plasma-desktop
cp -r samurai/themes/kuro /samurai/rootfs/usr/share/themes/samurai-kuro
cp -r samurai/themes/shiro /samurai/rootfs/usr/share/themes/samurai-shiro

# 4. Assemble and generate the ISO
rsync -a /samurai/rootfs/ iso/
xorriso -as iso -r -fjoliet-long -l -V "Samurai Linux" -o samurai.iso iso/

# 5. Checksum and sign
sha256sum samurai.iso > samurai.sha256
gpg --armor --output samurai.iso.sig samurai.iso

# 6. Boot-test
qemu-system-x86_64 -cdrom samurai.iso -m 4096 -display none -boot d
```

## Current Status

| Component | Status |
|---|---|
| Architecture & build documentation | ✅ Complete |
| Kuro / Shiro themes | ✅ Complete and verified |
| `samurai-ai` CLI (13 commands) | ✅ Working |
| `samurai-theme` CLI | ✅ Working |
| `samurai-gaming` CLI | ✅ Working |
| Repository pushed to `origin/main` | ✅ Done (`c0e88d9`) |
| Bootable ISO generation | ⚠️ Requires a build host with 50 GB+ disk and 8 GB+ RAM |

ISO generation could not run in the original (constrained) build environment —
see [RELEASE_DESCRIPTION.md](RELEASE_DESCRIPTION.md) for the continuation
checklist and the 17 release acceptance criteria.

## Post-Build Tooling

```bash
# Analyze a built ISO with REA
./scripts/analyze-iso.sh path/to/samurai.iso

# Run the combined post-build workflow (REA + Heretic)
./scripts/post-build-workflow.sh path/to/samurai.iso

# Decensor a model with Heretic (requires: pip install heretic-llm)
python3 scripts/use-heretic.py google/gemma-3-12b-it
```

## License

See [LICENSE](LICENSE).

---
*Samurai Linux — AI-Powered, Secure, High-Performance Developer and Gaming OS*
