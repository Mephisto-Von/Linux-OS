# Samurai Linux Installation and First Boot

## Bootable ISO

The ISO is built with Debian `live-build`; see
[`build/README.md`](../../build/README.md). The old direct `xorriso` recipe was
invalid (it produced a data ISO, not a bootable live image).

```bash
sudo bash build/build.sh
bash build/qemu-test.sh dist/samurai-linux-*-amd64.iso --gui
```

> The Calamares-based installer and first-boot wizard described below are the
> target design. The current ISO boots a live KDE Plasma session but does not yet
> ship an installer.

## Installation Steps

### 1. Language and Location
- Keyboard layout selection
- Locale settings

### 2. Network Detection
- Automatic hardware detection
- Wi-Fi or wired connection setup
- Proxy configuration if needed

### 3. Partition Selection
- **Guided partitioning** - recommended for new users
- **Manual partitioning** - advanced users
- **Full-disk encryption** - LUKS encrypted volumes supported
- **Separate /home** option

### 4. Full-Disk Encryption Options
- LUKS encryption during installation
- Prompt for passphrase
- Recovery key saved to user home (optional)
- No encryption option available

### 5. User Account Creation
- Username and password
- Strong password generation assistance
- Automatic login option (not recommended for security)
- Administrative user setup

### 6. Secure Administrator Configuration
- Sudo group membership
- SSH hardening guidance
- Root login disabled by default
- Sudo timeout configuration

### 7. Package Selection
- **Minimal install** - base system only
- **Developer profile** - core tools + editors
- **Gaming profile** - Steam, Proton, gaming tools
- **AI/Developer combo** - developer tools + AI runtime
- **Full install** - everything included

### 8. Developer and Gaming Profiles
```bash
# Select developer profile
samurai-install select-profile developer

# Select gaming profile
samurai-install select-profile gaming

# Select AI developer profile
samurai-install select-profile ai-dev
```

### 9. AI Runtime Setup
```bash
# Install Ollama
curl -s https://ollama.com/download/ollama-linux-amd64.tar.gz | tar -xz -C /usr/local/bin

# Pull default model
ollama pull llama3.2:3b

# Configure Samurai AI Assistant
samurai-ai configure --model llama3.2:3b

# Test inference
samurai-ai chat "Hello, how are you?"
```

### 10. Theme Selection
```bash
# Select Kuro (dark) theme
samurai-theme set kuro

# Select Shiro (light) theme  
samurai-theme set shiro

# Auto-switch based on time of day
samurai-theme auto
```

## First Boot Experience

### Initial Setup Wizard
1. Welcome and language selection
2. Network configuration
3. User account setup
4. Theme preference (Kuro/Shiro/Auto)
5. AI assistant setup (optional)
6. Developer tool installation prompt
7. Gaming profile installation prompt
8. Finish and login

### Post-Login Configuration
- Apply selected theme
- Initialize AI assistant
- Set up developer profile tools (if selected)
- Set up gaming profile (if selected)
- Check for updates
- Display introduction guide

### Recovery Guidance
- **Live ISO rescue** - boot from ISO and recover system
- **Backup configuration** - `/home/.samurai-backup/`
- **Repository recovery** - restore Samurai package repo
- **Theme recovery** - reinstall from `/usr/share/samurai/themes/`
