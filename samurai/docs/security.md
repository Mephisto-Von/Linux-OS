# Samurai Security Model

## Secure Defaults

### System Access
- **Root login disabled by default** - administrative tasks via sudo only
- **Sudo group membership** - granted only to the administrator account
- **Sudo timeout** - configurable, defaults to a short credentials cache
- **SSH hardening** - root login disabled, password auth off by default when
  keys are present, config documented in the installer

### Firewall
- **Default-deny inbound** - no listening services exposed without explicit rules
- **nftables/UFW** - managed firewall with documented rule sets
- **Outbound allowed** - with disclosure when AI features will transmit data

### Disk and Filesystem
- **Full-disk encryption** - LUKS supported during installation
- **Encrypted swap** - when LUKS full-disk encryption is enabled
- **Recovery key** - optionally saved to user home with a warning

## Package and Repository Security

### Signing
- **APT repository signing** - every package repository signed with a project GPG key
- **ISO checksums** - SHA-256 and SHA-1 published with every release
- **ISO signature** - GPG-armored detached signature (`samurai.iso.sig`)

### Updates
- **Security upgrades** - unattended-upgrades configured for critical fixes
- **Update testing** - upgrades validated on test systems before publication
- **Rollback guidance** - documented downgrade/recovery procedures

## AI Security

### Data Handling
- **No silent uploads** - files, source code, logs, credentials, and system info
  are never uploaded to cloud services without explicit user action
- **Cloud disclosure** - clear indication when a request will leave the device
  or incur charges
- **Permissioned execution** - AI-proposed privileged actions (package installs,
  sudo commands, disk/firewall changes, credential access) require explicit
  user confirmation

### Credential Storage
- **OS credential store** - API keys stored via KWallet/SecretService
- **CLI management**:
  ```bash
  samurai-ai credentials set <provider> <key>
  samurai-ai credentials get <provider>
  samurai-ai credentials remove <provider>
  ```
- **Local mode preferred** - privacy-sensitive work stays on-device

## Secure Boot
- **Unsigned ISO** - current builds do not ship a Secure Boot signature
- **Documentation** - users may sign the bootloader with their own MOK key
- **Planned**: project-signed builds in a future release

## Reporting Security Issues
- Report suspected vulnerabilities privately to the maintainers before public
  disclosure
- Critical defects block release until resolved or explicitly waived
  (see `release-process.md`)
