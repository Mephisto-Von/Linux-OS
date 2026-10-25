# Samurai Linux Architecture

## Distribution
- **Name**: Samurai Linux
- **Base**: Debian Stable (starting with Debian 13 "Trixie")
- **Development Model**: Custom distribution based on existing Linux distribution

## Base System
- **Architecture**: x86_64 initially
- **Package Format**: Debian packages (.deb) and compatible repository infrastructure

## Desktop Environment
- **Primary**: KDE Plasma
- **Themes**: 
  - **Kuro (Dark)**: 
    - Background: `#111214`
    - Panels: `#1B1D20`
    - Elevated surfaces: `#25272B`
    - Primary text: `#F2EEE5`
    - Secondary text: `#B8B4AC`
    - Crimson: `#B52832`
    - Gold: `#B89A59`
    - Borders: `#383A3D`
  - **Shiro (Light)**:
    - Background: `#F5F0E6`
    - Panels: `#ECE5D8`
    - Elevated surfaces: `#FFFDF8`
    - Primary text: `#242321`
    - Secondary text: `#686258`
    - Vermilion: `#B52832`
    - Gold: `#96733B`
    - Borders: `#D8D0C2`

## Product Objectives
1. Develop software and build applications
2. Run local AI models and interact with integrated AI assistant
3. Use optional cloud AI providers through explicit user configuration
4. Work securely with source code, credentials, containers, and development environments
5. Play supported games with practical Linux gaming tools
6. Use the machine for normal daily computing
7. Customize the desktop without sacrificing usability
8. Maintain and recover the system without advanced Linux expertise

## Modular Organization
- Base operating system and kernel
- Package and repository management
- Security and privacy layer
- KDE Plasma desktop and Samurai theme system
- AI runtime and assistant
- Developer toolchain
- Gaming environment
- System settings and performance manager
- Installer, updater, recovery, and diagnostics
- Build pipeline, tests, and release tooling

## AI-Powered Operating System
### 4.1 Local AI Runtime
- Evaluate maintained local inference engines (Ollama, llama.cpp)
- Implement model discovery, installation, storage, and deletion
- Hardware and memory detection (CPU/GPU capability)
- Model compatibility checks, context-length and memory-budget controls
- Inference status and resource monitoring
- Clear errors when model cannot run on available hardware

### 4.2 Samurai AI Assistant
- Desktop-accessible chat interface
- Conversation history with user-controlled retention
- Code explanation and debugging
- Project planning and implementation assistance
- File summarization and document analysis
- Terminal command explanations
- System troubleshooting
- Developer documentation assistance
- Optional speech input and output
- Configurable local model selection
- Optional cloud model integrations
- Modular provider interface

### 4.3 Intelligent Model Router
- Task category based selection (coding, reasoning, summarization, etc.)
- Available hardware consideration
- Model capabilities and measured quality
- Context-window requirements, memory and latency constraints
- Estimated cost, privacy requirements, provider availability
- User-selected preferences override

### 4.4 AI-Assisted System Operations
- Permissioned execution service
- Explicit confirmation for destructive/privileged operations
- Never silently upload files, source code, logs, credentials, or system info to cloud

### 4.5 Cloud and Offline Modes
- **Local mode**: Use locally available models without cloud API credentials
- **Cloud mode**: Configure supported providers with user's own credentials
- Secure credential storage, never hardcode secrets

## Developer Environment
### Core Tools
- Git and SSH, GCC and Clang, Make, CMake, Ninja
- Python and virtual environments, Node.js and npm-compatible workflows
- Rust and Cargo, Go, Java toolchains
- GDB and LLDB, Shell scripting utilities

### Editors and IDEs
- VS Code-compatible workflows
- VSCodium (open-source editor)
- Neovim/Vim
- Qt Creator
- JetBrains IDEs (supported installation methods)

### Containers and Virtualization
- Podman and rootless containers
- Docker-compatible workflows
- QEMU/KVM and libvirt
- Development containers, local databases, API-testing utilities

### AI/ML Development
- PyTorch and TensorFlow (optional)
- Jupyter, data science and scientific computing
- GPU compute, CUDA or ROCm when compatible
- Model development and evaluation, reproducible Python environments

## Security and Privacy
- Secure defaults without making development difficult
- Debian package signature verification
- Firewall configuration, least-privilege administration
- AppArmor mandatory access control
- Full-disk encryption support through installer
- Secure credential storage
- Application and container isolation
- SSH hardening guidance
- Audit logs and diagnostics
- Privacy-conscious defaults
- Recovery and backup procedures
- Dependency vulnerability scanning
- Build provenance and artifact integrity checks
- Secure Boot where signing workflow permits

## Gaming and Graphics
- Steam and Proton
- Vulkan, Mesa, AMD/Intel/NVIDIA graphics
- Lutris, Heroic Games Launcher
- GameMode, MangoHud, Gamescope
- Controllers and gaming audio devices

## Performance Engineering
- Minimal unnecessary startup applications
- Sensible background-service defaults
- Hardware-aware power profiles
- Balanced, performance, and power-saving modes
- Graphics and compositor configuration
- Storage and swap defaults
- Resource monitoring (CPU, RAM, GPU, disk, AI workloads)
- Optional AI resource limits
- Reproducible baselines for benchmarking

## KDE Plasma and Samurai Design System
- Kuro and Shiro themes as specified
- Original wallpapers, logos, icons, terminal colors, login branding, installer artwork
- Japanese Samurai-inspired motifs with restraint

## System Dashboard and Settings
- Samurai Control Center using KDE-compatible technologies
- System information, hardware/driver status, software/updates
- AI models and providers, development profiles, gaming configuration
- Performance profiles, security status, storage and backups
- Network settings, theme and personalization
- Diagnostics and logs

## Installer and First Boot
- Bootable ISO and installable system
- Live environment where feasible
- Hardware and network detection
- Partition selection, full-disk encryption options
- Bootloader configuration, user account creation
- Secure administrator configuration, package selection
- Developer and gaming profiles, AI runtime setup
- Theme selection, installation progress and actionable errors
- First-boot setup, recovery guidance
- Never erase disks without explicit user confirmation

## Package Management and Updates
- Debian's package ecosystem as foundation
- Maintained Samurai Linux repository for custom packages
- Package manifests, versioned releases, dependency management
- Package signature verification, repository metadata
- Security updates, upgrade testing, rollback/recovery guidance
- Clear conflict and failure reporting
- Controlled strategy for mixing repository types

## Build and Release Engineering
- Reproducible pipeline with 12 steps
- Version-controlled build configuration
- Pinned versions and documented update procedures

## Required Project Documentation
- README.md (this file)
- docs/architecture.md
- docs/build-guide.md
- docs/security.md
- docs/ai-system.md
- docs/developer-environment.md
- docs/gaming.md
- docs/performance.md
- docs/desktop-and-themes.md
- docs/installation.md
- docs/testing.md
- docs/release-process.md
- docs/known-limitations.md

## Release Acceptance Criteria
- Bootable ISO generated and validated
- Installation and first boot tested
- KDE Plasma works as primary desktop
- Kuro and Shiro themes persist and function
- Developer profile usable
- Security defaults and update mechanisms documented and tested
- AI assistant can use at least one supported model backend when configured
- Local AI mode works without requiring cloud API key
- Cloud integrations clearly disclose external data transmission
- Model routing uses documented criteria and permits user overrides
- Gaming capabilities tested on declared supported configurations
- Performance measurements reproducible
- Recovery and upgrade procedures documented
- Critical known defects resolved or explicitly block release
- Build and release instructions complete
