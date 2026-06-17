# openviking-nix

<!-- BEGIN generated:badges -->
[![CI](https://github.com/Daaboulex/openviking-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/Daaboulex/openviking-nix/actions/workflows/ci.yml)
[![NixOS unstable](https://img.shields.io/badge/NixOS-unstable-78C0E8?logo=nixos&logoColor=white)](https://nixos.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)
<!-- END generated:badges -->

NixOS package for [OpenViking](https://github.com/volcengine/OpenViking) — an agent-native context database for AI agents by ByteDance/Volcengine.

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

<!-- BEGIN generated:upstream -->
## Upstream

| | |
|---|---|
| **Project** | [Viking-Engineering/openviking](https://github.com/Viking-Engineering/openviking) |
| **License** | Apache-2.0 |
| **Tracked** | GitHub releases |
<!-- END generated:upstream -->

<!-- BEGIN generated:installation -->
## Installation

Add as a flake input:

```nix
{
  inputs.openviking = {
    url = "github:Daaboulex/openviking-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Then add the overlay:

```nix
nixpkgs.overlays = [ inputs.openviking.overlays.default ];
```

Import the NixOS module:

```nix
imports = [ inputs.openviking.nixosModules.default ];
```
<!-- END generated:installation -->

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
| `services.openviking.user` | string | `"openviking"` | User account to run as |
| `services.openviking.group` | string | `"openviking"` | Group account to run as |
| `services.openviking.extraGroups` | list of string | `[]` | Extra groups for the service |
| `services.openviking.port` | port | `1933` | Server listen port |
| `services.openviking.host` | string | `"127.0.0.1"` | Server bind address |
| `services.openviking.dataDir` | string | `"/var/lib/openviking"` | Data/workspace directory |
| `services.openviking.settings` | null or attrs | `null` | Declarative `ov.conf` settings |
| `services.openviking.readOnlyPaths` | list of string | `[]` | Extra paths for the service to read |
| `services.openviking.configFile` | null or path | `null` | Path to `ov.conf` (defaults to `dataDir/ov.conf`) |
| `services.openviking.openFirewall` | bool | `false` | Open firewall for server port |

### Configuration

#### Declarative Configuration (Recommended)

```nix
services.openviking = {
  enable = true;
  user = "user"; # Run as primary user to solve all permission issues for local indexing
  group = "users";
  readOnlyPaths = [ "/home/user/Documents/my-project" ];
  settings = {
    embedding.dense = {
      provider = "openai";
      model = "text-embedding-004";
      api_key = "your-api-key"; # Use sops-nix for security
      api_base = "https://generativelanguage.googleapis.com/v1beta/openai/";
      dimension = 768;
    };
    vlm = {
      provider = "litellm";
      model = "gemini/gemini-2.0-flash";
      api_key = "your-api-key";
    };
  };
};
```

*Note: Declarative configuration will place secrets in the Nix store. Use `configFile` pointing to a sops-managed file for production use.*

### Permissions and Indexing

OpenViking runs as a system user with `ProtectHome=true` by default. To index local directories in `/home`:

1.  **Run as your user**: Set `services.openviking.user = "youruser";` (Easiest and recommended for personal workstations).
2.  **Alternatively**: Keep `openviking` user, set `services.openviking.readOnlyPaths = [ "/path" ];`, and ensure permissions are correct on your home directory.

Supports OpenAI, Volcengine, Jina, and LiteLLM (for Claude, Gemini, etc.) providers. See [OpenViking docs](https://github.com/volcengine/OpenViking) for the full config reference.

## Platform

x86_64-linux only.

## Credits

- [OpenViking](https://github.com/volcengine/OpenViking) by ByteDance/Volcengine (Apache-2.0)
- Nix packaging by [@Daaboulex](https://github.com/Daaboulex)

## Development

```bash
git clone https://github.com/Daaboulex/openviking-nix
cd openviking-nix
nix develop                       # enter dev shell, installs pre-commit hooks
nix fmt                           # format flake
nix flake check --no-build        # eval check
nix build                         # builds the full openviking package
nix build .#agfs                  # AGFS server only
nix build .#ov-cli                # Rust CLI only
./result/bin/openviking --version # binary verify
```

CI runs the same chain daily; manual updates rarely needed.

<!-- BEGIN generated:options -->
## Options

This module declares options under `services.openviking`. See [`module.nix`](module.nix) for all available options.
<!-- END generated:options -->

## License

The Nix packaging code in this repo is [MIT](./LICENSE) licensed. Upstream OpenViking is [Apache-2.0](https://github.com/volcengine/OpenViking/blob/main/LICENSE).

<!-- BEGIN generated:footer -->
---

*Maintained as part of the [Daaboulex](https://github.com/Daaboulex) NixOS ecosystem.*
<!-- END generated:footer -->
