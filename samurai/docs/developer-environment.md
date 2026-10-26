# Samurai Developer Environment

> `samurai-editor` is a planned helper and is not included yet. Install editors
> with `apt` until it exists.

## Core Tools

### Version Control and SSH
- Git - pre-installed with Samurai developer profile
- SSH - configured with secure defaults
- GitHub/GitLab CLI integration

### Compilers and Build Systems
- GCC - system compiler
- Clang - alternative compiler with better C++ support
- Make - standard build automation
- CMake - cross-platform build system
- Ninja - fast build system for C++ projects

### Package Managers and Languages
- Python 3.x with venv support
- Node.js LTS with npm
- Rust (rustup) and Cargo
- Go (goenv or gvm)
- Java JDK with javac
- Shell utilities (bash, zsh, fish)

## Editors and IDEs

### VS Code-Compatible Workflows
- VSCodium - open-source VS Code fork (pre-installed or easy install)
- VS Code with Samurai extensions

### Native Editors
- Neovim - configured with lazy.nvim package manager
- Vim - enhanced vi editor
- Qt Creator - for Qt/C++ development
- JetBrains IDEs (IntelliJ, PyCharm, WebStorm) via snaps or scripts

### Editor Configuration

The Samurai editor configuration bundle is not shipped yet. Until it is,
install and configure editors yourself (for example `apt-get install neovim`
followed by your own `~/.config/nvim`).
