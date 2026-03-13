# openviking-nix

NixOS package for [OpenViking](https://github.com/volcengine/OpenViking) — an agent-native context database for AI agents.

## Packages

| Package | Description |
|---|---|
| `openviking` (default) | Full Python package with server, CLI, vector engine, and all native components |
| `agfs` | AGFS server binary + Python binding shared library (Go) |
| `ov-cli` | OpenViking CLI client (Rust) |

The main `openviking` package includes 4 binaries: `openviking-server`, `openviking`, `ov`, `vikingbot`.

## Build components

| Component | Language | Output |
|---|---|---|
| AGFS server | Go | `agfs-server` binary |
| AGFS binding | Go (CGO) | `libagfsbinding.so` |
| ov CLI | Rust | `ov` binary |
| Vector engine | C++17 / pybind11 | `engine.cpython-*.so` |
| OpenViking | Python (FastAPI) | Server + client library |

## Usage

### As a flake input

```nix
# flake.nix
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
  port = 1933;              # default
  host = "127.0.0.1";       # default
  dataDir = "/var/lib/openviking";
  # configFile = /path/to/ov.conf;
  openFirewall = false;
};
```

### Configuration

Create `~/.openviking/ov.conf` (JSON) with your embedding model and LLM endpoints. Supports OpenAI, Volcengine, Jina, and LiteLLM providers. See [OpenViking docs](https://github.com/volcengine/OpenViking) for the full config reference.

## Platform

x86_64-linux only. The C++ vector engine and pre-built tree-sitter grammar wheels are architecture-specific.

## License

Apache-2.0 (same as upstream OpenViking).
