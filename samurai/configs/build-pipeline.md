# Samurai Build and Release Engineering

> **Legacy document.** The maintained build is `build/build.sh` with Debian
> `live-build`; see [`build/README.md`](../../build/README.md). The commands
> below are retained for history and must not be used to build a release.

## Reproducible Pipeline - 12 Steps

### Step 1: Verify Host Environment
```bash
# Check disk space
df -h /path/to/build

# Check memory
free -h

# Verify architecture
uname -m

# Check available tools
which debootstrap sbuild xorriso

# Minimum requirements:
# - 50GB free disk (100GB+ recommended)
# - 8GB RAM (16GB+ recommended)
# - x86_64 architecture
# - debootstrap, sbuild, xorriso installed
```

### Step 2: Retrieve Source Code and Assets
```bash
# Initialize git repository
git init samurai/
cd samurai

# Pull Debian base system
debootstrap --arch=amd64 trixie /samurai/rootfs http://deb.debian.org/debian/

# Pull Samurai configuration and assets
# (clone from distribution repo or set up local source)
git clone <samurai-config-repo> configs/
```

### Step 3: Verify Package and Source Integrity
```bash
# Import Debian archive keys
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <key>

# Or with keyring
debootstrap --keyring=/usr/share/keyrings/debian-archive-keyring.gpg

# Verify package signatures
dpkg-sig --verify <package>.deb
```

### Step 4: Build Custom Packages
```bash
# Create Samurai package directories
mkdir -p samurai/packages/{main,contrib,non-free}

# Build custom packages
cd samurai/packages
dpkg-buildpackage -us -uc -j$(nproc)

# Or use sbuild
sbuild -A -d trixie -h /samurai/rootfs samurai-build
```

### Step 5: Assemble Customized Debian Filesystem
```bash
# Method 1: sbuild
sbuild -A -d trixie -h samurai/rootfs samurai-build

# Method 2: Manual overlay
cp samurai/packages/*.deb /samurai/rootfs/var/cache/apt/archives/
chroot /samurai/rootfs apt-get update
chroot /samurai/rootfs apt-get install -y \
    kde-plasma-desktop \
    samurai-theme \
    samurai-ai \
    samurai-gaming
```

### Step 6: Integrate KDE Plasma and Samurai Configuration
```bash
# Install KDE Plasma desktop
chroot /samurai/rootfs apt-get install -y kde-plasma-desktop

# Apply Samurai themes
cp -r /opt/samurai/themes/kuro /usr/share/themes/samurai-kuro
cp -r /opt/samurai/themes/shiro /usr/share/themes/samurai-shiro

# Configure Samurai welcome script
cp /opt/samurai/scripts/welcome.desktop /usr/share/xsessions/

# Set default session
echo "Exec=/opt/samurai/scripts/start-plasma.sh" >> /usr/share/xsessions/samurai-kuro.desktop
```

### Step 7: Generate ISO
```bash
# Supported pipeline
sudo bash build/build.sh
```

The legacy `xorriso` recipe was invalid and produced a non-bootable data ISO.

### Step 8: Calculate Checksums
```bash
sha256sum samurai-linux-*.iso > samurai-linux-*.iso.sha256
gpg --armor --detach-sign --output samurai-linux-*.iso.sig samurai-linux-*.iso

# Verify
sha256sum -c samurai-linux-*.iso.sha256
gpg --verify samurai-linux-*.iso.sig samurai-linux-*.iso
```

### Step 9: Validate Packages and Image Contents
```bash
# Verify ISO is bootable (QEMU test)
qemu-system-x86_64 -cdrom samurai.iso -m 2048 -display none -boot d

# Check all packages install correctly
dpkg -V samurai-theme samurai-ai samurai-gaming

# Validate filesystem hierarchy
find iso/ -type f | wc -l

# Run integration tests
./scripts/test-installation.sh
```

### Step 10: Run Automated Tests
```bash
# Boot-test in QEMU
qemu-system-x86_64 -cdrom samurai.iso -m 4096 -display none

# Test installation
./scripts/test-full-install.sh

# Verify KDE Plasma works
# Check display manager, desktop session

# Verify themes apply correctly
# Check color schemes, panel settings

# Verify AI runtime components
# Check Ollama, model availability
```

### Step 11: Boot-Test the Image
```bash
# Virtual machine test
qemu-system-x86_64 -cdrom samurai.iso -m 4096 -boot d

# Real hardware testing where possible
# Document results in testing.md

# Test common workflows:
# - Login and desktop load
# - Network connectivity
# - Package installation
# - Theme selection
```

### Step 12: Produce Release Notes and Known Limitations
```bash
# Document what works
# Document known issues
# List supported hardware
# Note any limitations

# Sample release notes format:
## Samurai Linux 1.0 Release Notes

### New Features
- KDE Plasma desktop with Kuro/Shiro themes
- Samurai AI Assistant with local model support
- Developer toolchain (GCC, Clang, IDEs)
- Gaming environment (Steam, Proton, GameMode)

### Known Limitations
- [list any known issues]
- [hardware not yet tested]
- [features in development]

### System Requirements
- Minimum: 50GB disk, 8GB RAM, 2-core CPU
- Recommended: 100GB disk, 16GB RAM, 4-core CPU

### Upgrade Path
- From: Previous Samurai version
- To: samurai-1.0
- Steps: [upgrade procedure]
