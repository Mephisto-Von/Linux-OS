# Samurai Developer Environment

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
```bash
# Install Samurai editor configs
samurai-editor install --all

# Apply Samurai theme to Neovim
ln -sf /opt/samurai/configs/nvim ~/.config/nvim

# VS Code settings sync
code --user-data-dir ~/.vscode-samurai --extensions-dir ~/.vscode-extensions
```
