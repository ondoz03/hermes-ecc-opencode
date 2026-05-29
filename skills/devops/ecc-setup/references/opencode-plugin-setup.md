# OpenCode ECC Plugin — Agent & Command Discovery

## The Problem
Configuring OpenCode with just `{"plugin": ["ecc-universal"]}` does NOT register agents or commands. The plugin field only tells OpenCode to load the npm package as a module — the actual agent definitions and command mappings must be declared in `opencode.json`.

## How OpenCode Discovers Agents & Commands

OpenCode reads agents and commands from the `agent` and `command` keys in `opencode.json`:

```json
{
  "agent": {
    "security-reviewer": {
      "description": "Security vulnerability detection...",
      "mode": "subagent",
      "model": "anthropic/claude-opus-4-5",
      "prompt": "{file:prompts/agents/security-reviewer.txt}",
      "tools": {"read": true, "bash": true, "write": true, "edit": true}
    }
  },
  "command": {
    "security": {
      "description": "Run comprehensive security review",
      "template": "{file:commands/security.md}\n\n$ARGUMENTS",
      "agent": "security-reviewer",
      "subtask": true
    }
  }
}
```

The `plugin: ["ecc-universal"]` field loads:
- Shared tools
- MCP configurations
- Module-level extensions

But agents and commands must be defined in the project's `opencode.json`.

## Source of Truth

The ECC package ships a full `opencode.json` inside:
```
~/.hermes/node/lib/node_modules/ecc-universal/.opencode/opencode.json
```

This file contains 25 agents and 26 commands. For the full 63 agents + 79 commands, use the ECC repo's version:
```
/home/who/herd/ECC/.opencode/opencode.json
```

## Setup Commands

```bash
# Quick setup from package (25 agents)
cp -r ~/.hermes/node/lib/node_modules/ecc-universal/.opencode/* .opencode/

# Full setup from repo (63 agents)
cp -r /home/who/herd/ECC/.opencode/* .opencode/

# Using ecc-init script
ecc-init
```

## Pitfalls

- **Plugin != Agent config.** Don't confuse them. Plugin loads modules; agent config adds `/commands`.
- **Missing prompts.** The `prompt: "{file:...}"` references need the actual prompt files. Copy the entire `.opencode/` directory, not just `opencode.json`.
- **Model not found.** Default models (`claude-opus-4-5`, `claude-sonnet-4-5`) might not be available in your provider. Change `model` fields in `opencode.json` to match your OpenCode provider config. If you get "model X is not valid", run: `sed -i 's/claude-.*-4-5/deepseek-v4-flash/g' .opencode/opencode.json`.
- **Version mismatch.** npm package `ecc-universal@1.10.0` has fewer agents than repo `v2.0.0-rc.1`.
