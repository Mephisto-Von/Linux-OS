# Samurai Linux Installation and First Boot

## Bootable ISO

The ISO is built with Debian `live-build`; see
[`build/README.md`](../../build/README.md). The old direct `xorriso` recipe was
invalid (it produced a data ISO, not a bootable live image).

Build locally:

```bash
sudo bash build/build.sh
bash build/verify-iso.sh dist/samurai-linux-*-amd64.iso
bash build/qemu-test.sh dist/samurai-linux-*-amd64.iso --gui
```

Or download the `samurai-linux-iso` artifact from the latest successful
**Build ISO (hosted)** run in GitHub Actions. The workflow builds the ISO,
verifies the live rootfs, and boots it headlessly in QEMU before uploading it.

Verify the download and write it to a USB drive:

```bash
cd dist
sha256sum -c ./*.sha256

# Replace /dev/sdX with the USB device, not a partition. This erases it.
sudo dd if=samurai-linux-*-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

The hybrid ISO boots on BIOS and UEFI systems. The live image uses Debian's
signed UEFI shim, so it can boot with Secure Boot enabled. The **installed**
system uses unsigned GRUB by default; disable Secure Boot or sign the installed
bootloader if you need Secure Boot.

## Live Session

1. Boot the USB drive and choose **Samurai Linux** in the boot menu.
2. The live session logs in as `samurai` (password `live` if asked). `sudo` is
   passwordless in the live session.
3. Connect to the network from the Plasma system tray if you want to install
   updates or packages after installation.
4. Start the installer from the desktop icon or the application menu entry
   **Install Samurai Linux**.

## Installation with Calamares

The ISO ships Calamares with Debian's live-install configuration and Samurai
branding. The steps are:

1. **Welcome** - choose language and continue.
2. **Location** - choose region and time zone.
3. **Keyboard** - choose the keyboard layout.
4. **Partitions** - use guided partitioning for a simple install, or manual
   partitioning for a custom layout. LUKS full-disk encryption is available in
   the partitioner.
5. **Users** - create the account you will use after installation.
6. **Summary** - review the disk changes. This is the last point before the
   installer writes to disk.
7. **Install** - Calamares unpacks the live filesystem, installs GRUB for BIOS
   or UEFI, and creates the initial initramfs.
8. **Finish** - reboot and remove the USB drive.

Notes:

- Use a disk of at least 20 GB. Back up existing data first.
- The installer copies the live rootfs, so the installed system contains the
  same KDE desktop, Samurai CLIs, themes, and installer packages.
- A network connection is not required for the base installation.
- On UEFI systems, the installer creates an EFI system partition and installs
  GRUB there. On BIOS systems it installs GRUB to the disk's boot area.
- If the machine has Secure Boot enabled and the installed system does not boot,
  disable Secure Boot in firmware or sign the installed GRUB with your own keys.

The current installer is Debian's packaged Calamares configuration plus Samurai
branding. Samurai-specific package-profile screens and a custom first-boot
wizard are not implemented.

## First Boot

After rebooting into the installed system, log in with the account created by
Calamares. There is no first-boot wizard; finish setup from a terminal:

```bash
# Update the installed system
sudo apt update
sudo apt full-upgrade

# Theme: Kuro is applied for new users; switch or inspect it with:
samurai-theme list
samurai-theme status
samurai-theme set kuro
samurai-theme set shiro

# AI assistant: install Ollama separately, then choose a model
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2:3b
samurai-ai set-default llama3.2:3b
samurai-ai chat "Hello"

# Gaming: install the profile, then launch Steam
samurai-gaming install-profile
samurai-gaming steam
```

Steam, Ollama, and AI models are not included in the ISO. Large models need
enough RAM or a compatible GPU; run `samurai-ai check-compatibility` for
guidance.

## Current Limitations

- The Calamares installer is integrated, but the full interactive installation
  is not yet automated in CI. The hosted workflow verifies the live rootfs and
  boots the ISO; a scripted QEMU install to a virtual disk is still future work.
- There is no Samurai first-boot wizard and no `samurai-install` command.
- The installed system's bootloader is not Secure Boot signed.
- There is no signed APT repository; the installed system uses Debian's
  repositories plus the packages copied from the live image.
- Wallpapers, icons, and cursors are not yet packaged as a complete Samurai
  theme.

## Recovery

- **Live ISO rescue** - boot the ISO, mount the installed partitions, and
  `chroot` into the system to repair packages or the bootloader.
- **Reinstall GRUB from the live session** - mount the target root and EFI
  system partition, bind-mount `/dev`, `/proc`, and `/sys`, then run
  `grub-install` and `update-grub` inside the chroot.
- **Backups** - keep a separate backup of `/home` and any custom configuration
  before reinstalling or repartitioning.
