# Samurai AI System Configuration

> **Status:** implemented today are Ollama-backed chat, model install/delete/list,
> hardware and memory reporting, a rough RAM-fit estimate, and credential
> storage. The desktop widget, model router, automatic inference pausing, and
> AI-assisted system operations are planned.

## 4.1 Local AI Runtime

### Engine Selection
- **Implemented**: Ollama (the CLI shells out to `ollama run`, `pull`, `rm`, `list`)
- **Planned**: a provider abstraction for direct llama.cpp or other engines

### Model Discovery and Installation
```bash
# List available models
samurai-ai list-models

# Install a model
samurai-ai install-model <model-id>

# Delete a model
samurai-ai delete-model <model-name>
```

### Hardware Detection
```bash
# Check GPU availability
samurai-ai gpu-info

# CPU capability check
samurai-ai cpu-info

# Memory budget
samurai-ai memory-budget
```

### Model Configuration
```bash
# Set default model
samurai-ai set-default <model-id>

# Check model compatibility
samurai-ai check-compatibility <model-id>

# View inference status
samurai-ai status
```

### Resource Controls
- **Implemented**: a suggested model budget of 1/8 of system RAM and a rough
  parameter-count/RAM compatibility estimate
- **Planned**: context-length limits enforced by the runtime, and automatic
  inference pause when system load is high

## 4.2 Samurai AI Assistant

### Interface (planned)
- **Desktop widget**: KDE Plasma applet
- **Keyboard shortcut**: `Ctrl`+`Space` to activate
- **System tray** indicator for status

Currently the assistant is terminal-only: `samurai-ai chat "..."`.

### Features
- Chat interface with conversation history
- User-controlled retention (configurable TTL)
- Code explanation and debugging assistance
- Project planning and implementation assistance
- File summarization and document analysis
- Terminal command explanations
- System troubleshooting guidance
- Developer documentation assistance

### Optional Features
- Speech input (via Whisper or similar)
- Speech output (via eSpeak or similar)
- Cloud model integrations (OpenAI, Anthropic, etc.)

## 4.3 Intelligent Model Router (planned)

### Task Categories
- **Coding**: Model selection for programming tasks
- **Reasoning**: For logical analysis and problem-solving
- **Summarization**: Document and meeting summary generation
- **Lightweight chat**: Casual conversation
- **Document analysis**: Text extraction and analysis
- **Local offline**: Models that run entirely on-device

### Selection Criteria
1. Available hardware (CPU/GPU, VRAM, system RAM)
2. Context-window requirements vs. available memory
3. Measured quality benchmarks (when available)
4. Memory and latency constraints
5. Estimated cost (for cloud providers)
6. Privacy requirements (local vs. cloud)
7. Provider availability
8. User-selected preferences

### Router Output
```
Recommended model: gemma-3-12b-it (local)
Task: code explanation
Estimated latency: 2.3s per 100 tokens
Will stay on-device: Yes
Cost: $0.00
```

## 4.4 AI-Assisted System Operations (planned)

### Permissioned Execution
All AI-proposed actions require explicit user confirmation for:
- Package installation/removal
- Privileged commands (sudo, etc.)
- Disk changes
- Firewall modifications
- Credential access
- Security-sensitive changes

### Supported Tasks
- Installing approved packages
- Creating development environments
- Generating project scaffolding
- Running tests
- Diagnosing logs
- Configuring development tools
- Managing model installations
- Explaining system configuration changes

### Safety Controls
- Never silently upload files, source code, logs, credentials, or system info to cloud
- Clear disclosure when request will leave device or incur charges
- User override always available

## 4.5 Cloud and Offline Modes

### Local Mode
- Uses locally available models
- No cloud API credentials required
- Subject to model and hardware limitations
- Preferred for privacy-sensitive work

### Cloud Mode (planned)
- Users configure supported providers with their own credentials
- Supported providers: OpenAI, Anthropic, Google, local Ollama instances
- Credentials stored in OS credential store (Kwallet/SecretService)
- Clearly disclose external data transmission

### Credential Storage
```bash
# Store an API key in the Secret Service (libsecret / KWallet)
samurai-ai credentials set <provider> <key>

# Retrieve it (prints only the key, for scripting)
samurai-ai credentials get <provider>

# Remove it
samurai-ai credentials remove <provider>
```

`samurai-ai` uses `secret-tool` when available. If no Secret Service is running,
it falls back to `~/.config/samurai/credentials` with mode `0600` and prints a
warning; that fallback is **not encrypted**. Set `SAMURAI_AI_FORCE_FILE=1` to
force the file backend for testing.
