# openviking-nix

NixOS package for [OpenViking](https://github.com/volcengine/OpenViking) — an agent-native context database for AI agents by ByteDance/Volcengine.

[![Build](https://github.com/Daaboulex/openviking-nix/actions/workflows/build.yml/badge.svg)](https://github.com/Daaboulex/openviking-nix/actions/workflows/build.yml)

## Overview

OpenViking organizes agent context (memory, resources, skills) through a virtual filesystem paradigm using `viking://` protocol paths. It features tiered context loading (L0/L1/L2), hierarchical RAG, automatic session management, and a chat bot framework.

This repo packages the entire OpenViking stack for NixOS from a 4-language monorepo build:

| Component | Language | Output |
|---|---|---|
| AGFS server | Go | `agfs-server` binary |
| AGFS binding | Go (CGO) | `libagfsbinding.so` |
| ov CLI | Rust | `ov` binary |
| Vector engine | C++17 / pybind11 | `engine.cpython-*.so` |
| OpenViking | Python (FastAPI) | Server + client library |

## Packages

| Package | Description |
|---|---|
| `openviking` (default) | Full package with server, CLI, vector engine, and all native components |
| `agfs` | AGFS server binary + Python binding shared library |
| `ov-cli` | OpenViking Rust CLI client |

The main `openviking` package provides 4 binaries: `openviking-server`, `openviking`, `ov`, `vikingbot`.

## Usage

### Flake input

```nix
inputs.openviking = {
  url = "github:Daaboulex/openviking-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### Overlay

```nix
nixpkgs.overlays = [ inputs.openviking.overlays.default ];
# Provides: pkgs.openviking, pkgs.agfs, pkgs.ov-cli
```

### NixOS module (systemd service)

```nix
imports = [ inputs.openviking.nixosModules.default ];

services.openviking = {
  enable = true;
  port = 1933;                 # default
  host = "127.0.0.1";          # default
  dataDir = "/var/lib/openviking";
  # configFile = /path/to/ov.conf;
  openFirewall = false;        # default
};
```

The service runs with `DynamicUser`, `ProtectSystem=strict`, `NoNewPrivileges`, and other systemd hardening options.

### NixOS module options

| Option | Type | Default | Description |
|---|---|---|---|
| `services.openviking.enable` | bool | `false` | Enable the OpenViking server |
| `services.openviking.package` | package | `openviking` | Package to use |
| `services.openviking.port` | port | `1933` | Server listen port |
| `services.openviking.host` | string | `"127.0.0.1"` | Server bind address |
| `services.openviking.dataDir` | string | `"/var/lib/openviking"` | Data/workspace directory |
| `services.openviking.configFile` | null or path | `null` | Path to `ov.conf` (defaults to `dataDir/ov.conf`) |
| `services.openviking.openFirewall` | bool | `false` | Open firewall for server port |

### Configuration

Create `~/.openviking/ov.conf` (JSON) with your embedding model and LLM endpoints:

```json
{
  "storage": { "workspace": "./data", "vectordb": { "backend": "local" }, "agfs": { "backend": "local" } },
  "embedding": {
    "dense": {
      "provider": "openai",
      "api_base": "https://api.openai.com/v1",
      "api_key": "your-key",
      "model": "text-embedding-3-small",
      "dimension": 1536
    }
  },
  "vlm": {
    "provider": "openai",
    "api_base": "https://api.openai.com/v1",
    "api_key": "your-key",
    "model": "gpt-4o"
  }
}
```

Supports OpenAI, Volcengine, Jina, and LiteLLM (for Claude, Gemini, etc.) providers. See [OpenViking docs](https://github.com/volcengine/OpenViking) for the full config reference.

## Platform

x86_64-linux only.

## Credits

- [OpenViking](https://github.com/volcengine/OpenViking) by ByteDance/Volcengine (Apache-2.0)
- Nix packaging by [@Daaboulex](https://github.com/Daaboulex)

## License

Apache-2.0 (same as upstream OpenViking).
