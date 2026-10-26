# Samurai Gaming Configuration

> **Implemented today:** `samurai-gaming install-profile` installs
> `steam-installer` (Debian `contrib`), GameMode, and MangoHUD, plus optional
> Lutris/Gamescope when available. `samurai-gaming steam|lutris` launches through
> GameMode and MangoHUD. Automatic controller setup and redistributable
> installation are not implemented.

## Gaming Support

### Compatibility Layer
- **Steam** - Official Steam client with Proton for Windows game support
- **Proton** - Valve's compatibility layer (regular updates included)
- **Lutris** - Game management for non-Steam titles
- **Heroic Games Launcher** - Epic Games Store, GOG, and other launchers

### Graphics and Vulkan
- **Mesa** - Open-source graphics driver support
- **Vulkan** - Latest version with compatibility checks
- **AMD graphics** - Full support with amdgpu
- **Intel graphics** - Integrated support with i915/i965
- **NVIDIA graphics** - Via NVIDIA drivers or nouveau

### Gaming Enhancers
- **GameMode** - Optimizes system for gaming performance
- **MangoHud** - Performance overlay (FPS, latency, CPU/GPU usage)
- **Gamescope** - Secure session management for fullscreen windows

### Controller and Audio Support
- **Xbox and PlayStation controllers** - DualShock, XInput support
- **Gaming audio devices** - ALSA/PulseAudio configuration
- **RetroArch** - Classic game emulation

### Gaming Profile
Samurai includes a gaming profile that:
1. Launches Steam with Proton enabled
2. Sets GameMode as default for fullscreen games
3. Configures MangoHud for performance monitoring
4. Enables controller support out-of-the-box
5. Installs common redistributables (vcrun, physx, etc.)

### Supported Gaming Tools Installation
```bash
# Install gaming profile
samurai-gaming install-profile

# Launch Steam with gaming optimizations
samurai-gaming steam

# Launch Lutris with Samurai configuration
samurai-gaming lutris

# Toggle GameMode (user service)
systemctl --user start gamemoded

# Monitor with MangoHUD (Steam launch option form)
MANGOHUD=1 %command%
```

### Compatibility Notes
- Not all games will work (anti-cheat, DRM, proprietary drivers)
- Advanced overclocking and risky performance changes are optional
- NVIDIA driver setup is documented but not auto-configured
- Some anti-cheat systems may not work under Proton
