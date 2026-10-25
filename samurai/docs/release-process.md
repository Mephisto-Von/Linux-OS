# Samurai Linux Release Process

## Versioning
- **Format**: `YYYY.MM` (calendar versioning, e.g. `2026.10`)
- **Point releases**: security and critical-bug fixes only
- **Repository**: versioned APT repositories per release, plus `stable` and
  `unstable` channels

## Release Pipeline
1. Verify the build host (50 GB+ disk, 8 GB+ RAM, x86_64)
2. Bootstrap and customize the rootfs (`build-guide.md`, steps 2-6)
3. Generate the ISO with `xorriso`
4. Calculate checksums and sign:
   ```bash
   sha256sum samurai.iso > samurai.sha256
   sha1sum samurai.iso > samurai.sha1
   gpg --armor --output samurai.iso.sig samurai.iso
   ```
5. Run the test suite (`testing.md`)
6. Validate against the acceptance criteria below
7. Publish ISO, checksums, signature, and release notes

## Release Acceptance Criteria

A release may ship only when every criterion passes or is explicitly waived
with a documented reason:

1. Bootable ISO generated and validated
2. Installation and first boot tested
3. KDE Plasma works as the primary desktop
4. Kuro and Shiro themes persist and function
5. Developer profile usable
6. Security defaults and update mechanisms documented and tested
7. AI assistant can use at least one supported model backend when configured
8. Local AI mode works without requiring a cloud API key
9. Cloud integrations clearly disclose external data transmission
10. Model routing uses documented criteria and permits user overrides
11. Gaming capabilities tested on declared supported configurations
12. Performance measurements reproducible
13. Recovery and upgrade procedures documented
14. Critical known defects resolved or explicitly block release
15. Build and release instructions complete
16. Checksums and GPG signature verify against the published ISO
17. APT repository publication and upgrade path from the previous release tested

## Signing and Publication
- **ISO**: SHA-256/SHA-1 checksums plus GPG-armored detached signature
- **Packages**: every APT repository signed with the project key
- **Release notes**: known limitations, upgrade instructions, checksums
- **Archive**: previous releases kept available for downgrade/recovery

## Hotfix and Rollback
- **Hotfixes**: point release built from the tagged source with only the fix applied
- **Repository rollback**: previous package versions retained; pinning guidance
  in `package-management.md`
- **ISO rollback**: previous ISO remains downloadable until superseded and verified
