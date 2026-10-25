# Samurai Linux Build Guide

## Prerequisites

### Host Environment
- **Architecture**: x86_64
- **Disk Space**: minimum 50GB free (100GB+ recommended)
- **RAM**: minimum 8GB (16GB+ recommended for build)
- **Swap**: 8GB-16GB if RAM < 16GB
- **CPU**: 2-core minimum, 4-core+ recommended

### Required Tools
- `debootstrap` - Debian base system installer
- `sbuild` or `cowbuilder` - for building in clean chroot
- `git` - for source control
- `gnupg` - for package signature verification
- `dpkg-dev` - Debian package development tools
- `apt-get` - for package management
- `xorriso` - for ISO image creation
- `mkisofs` or `genisoimage` - ISO image generation
- `findutils`, `coreutils` - file operations

### Recommended
- `vim` or `neovim` - for editing configuration
- `screen` or `tmux` - for long-running build sessions
- `curl` and `wget` - for downloading files

## Distribution Configuration

### Debian Version
- **Starting**: Debian 13 "Trixie" (testing)
- **Verify**: Current supported point release and security status before building
- **Mirror**: Use official Debian mirrors (`deb.debian.org`)

### Samurai Repository
- Create maintained Samurai Linux repository at `samurai-repo/`
- Include custom packages, branding, configuration
- Package signature verification setup

## Build Pipeline

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
```

### Step 2: Retrieve Source Code and Assets
```bash
# Initialize git repository (if not already)
git init samurai/

# Pull Debian base system
debootstrap --arch=x86_64 trixie /samurai/rootfs http://deb.debian.org/debian/

# Pull Samurai configuration and assets
# (clone from distribution repo or set up local source)
```

### Step 3: Verify Package and Source Integrity
```bash
# Import Debian archive keys
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys <key>

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
```

### Step 5: Assemble Customized Debian Filesystem
```bash
# Use sbuild or manual method
sbuild -A -d trixie -h samurai/rootfs samurai-build

# Or manually overlay packages
cp samurai/packages/*.deb /samurai/rootfs/var/cache/apt/archives/
chroot /samurai/rootfs apt-get install -y ./*.deb
```

### Step 6: Integrate KDE Plasma and Samurai Configuration
```bash
# Install KDE Plasma desktop
chroot /samurai/rootfs apt-get install -y kde-plasma-desktop

# Apply Samurai themes and branding
cp -r samurai/themes/kuro /usr/share/themes/
cp -r samurai/themes/shiro /usr/share/themes/

# Configure Samurai welcome script, desktop entries, etc.
```

### Step 7: Generate ISO
```bash
# Create ISO directory structure
mkdir -p iso/boot/grub
mkdir -p iso/live

# Copy root filesystem
rsync -a /samurai/rootfs/ iso/

# Configure GRUB for live system
cat > iso/boot/grub/grub.cfg << 'GRUB_CFG'
# Samurai Linux GRUB configuration
menuentry 'Samurai Linux' {
    set isofile=/samurai.iso
    linux (isofile)/boot/vmlinuz boot=live config quiet
    initrd (isofile)/boot/initrd.img
}
GRUB_CFG

# Generate ISO
xorriso -as iso -r -fjoliet-long -l -V "Samurai Linux" \
  -o samurai.iso iso/
```

### Step 8: Calculate Checksums
```bash
sha256sum samurai.iso > samurai.sha256
sha1sum samurai.iso > samurai.sha1
gpg --armor --output samurai.iso.sig < samurai.iso
```

### Step 9: Validate Packages and Image Contents
```bash
# Verify ISO is bootable
# Check all packages install correctly
# Validate filesystem hierarchy

# Run integration tests
./scripts/test-installation.sh
```

### Step 10: Run Automated Tests
```bash
# Boot-test in QEMU
qemu-system-x86_64 -cdrom samurai.iso -m 2048 -display none

# Test installation
./scripts/test-full-install.sh

# Verify KDE Plasma works
# Verify themes apply correctly
# Verify AI runtime components
```

### Step 11: Boot-Test the Image
```bash
# Virtual machine test
qemu-system-x86_64 -cdrom samurai.iso -m 4096 -boot d

# Real hardware testing where possible
# Document results
```

### Step 12: Produce Release Notes and Known Limitations
```bash
# Document what works
# Document known issues
# List supported hardware
# Note any limitations
```

## Release Process

### Version numbering
- **Major**: When release acceptance criteria are fully met
- **Minor**: When significant features are added
- **Patch**: When bugs are fixed or documentation updated

### Before release
- [ ] Bootable ISO generated and validated
- [ ] Installation and first boot tested
- [ ] KDE Plasma works as primary desktop
- [ ] Kuro and Shiro themes persist and function
- [ ] Developer profile usable
- [ ] Security defaults and update mechanisms documented and tested
- [ ] AI assistant can use at least one supported model backend when configured
- [ ] Local AI mode works without requiring cloud API key
- [ ] Cloud integrations clearly disclose external data transmission
- [ ] Model routing uses documented criteria and permits user overrides
- [ ] Gaming capabilities tested on declared supported configurations
- [ ] Performance measurements reproducible
- [ ] Recovery and upgrade procedures documented
- [ ] Critical known defects resolved or explicitly block release
- [ ] Build and release instructions complete

### Release signing
```bash
gpg --detach-sign samurai.iso
gpg --armor --output samurai.tar.xz.sig samurai.tar.xz
```

## Troubleshooting

### Common Build Issues

1. **Insufficient disk space**
   - Solution: Free up space or use thinner filesystem layers

2. **Out of memory during build**
   - Solution: Increase swap, reduce parallel jobs (`-j` flag)

3. **GPG key import failures**
   - Solution: Use `apt-key` or `dpkg-sig` with correct keys

4. **GRUB configuration errors**
   - Solution: Verify `grub.cfg` syntax, test in QEMU first

5. **KDE Plasma fails to start**
   - Solution: Check `xorg.conf`, verify GPU drivers, check `.xsession-errors`

### Build Environment Recommendations
- Use a dedicated build partition or VM with 50GB+ and 8GB+ RAM
- Keep build logs for reproducibility
- Version-control all configuration changes
- Test each build step before proceeding to next
