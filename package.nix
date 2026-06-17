# OpenViking — agent-native context database for AI agents.
# Python package with an embedded C++17 pybind11 vector engine, plus the
# pre-built `ov` Rust CLI and the `ragfs_python` PyO3 extension (the Rust
# RAGFS binding — replaces the old Go AGFS / libagfsbinding.so).
{
  lib,
  python3Packages,
  fetchurl,
  cmake,
  src,
  version,
  ov-cli,
  ragfs-python,
}:

let
  # Tree-sitter grammar Python bindings missing from nixpkgs.
  # Pre-built manylinux wheels avoid ABI mismatch between the grammar C
  # source and nixpkgs' tree-sitter parser.h.
  mkTreeSitterWheel =
    {
      pname,
      grammarVersion,
      url,
      hash,
    }:
    python3Packages.buildPythonPackage {
      inherit pname;
      version = grammarVersion;
      format = "wheel";
      src = fetchurl { inherit url hash; };
      dependencies = [ python3Packages.tree-sitter ];
      doCheck = false;
      meta.license = lib.licenses.mit;
    };

  tree-sitter-typescript = mkTreeSitterWheel {
    pname = "tree-sitter-typescript";
    grammarVersion = "0.23.2";
    url = "https://files.pythonhosted.org/packages/49/d1/a71c36da6e2b8a4ed5e2970819b86ef13ba77ac40d9e333cb17df6a2c5db/tree_sitter_typescript-0.23.2-cp39-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
    hash = "sha256-6W02uFvKzeuP9cJhjXVZPvEuuvG06s40d+K9squxdSw=";
  };
  tree-sitter-java = mkTreeSitterWheel {
    pname = "tree-sitter-java";
    grammarVersion = "0.23.5";
    url = "https://files.pythonhosted.org/packages/29/09/e0d08f5c212062fd046db35c1015a2621c2631bc8b4aae5740d7adb276ad/tree_sitter_java-0.23.5-cp39-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
    hash = "sha256-NwsgS5UAuEf20MWtWEBFgxzuaemj5Nh4U1055KfkxPE=";
  };
  tree-sitter-cpp = mkTreeSitterWheel {
    pname = "tree-sitter-cpp";
    grammarVersion = "0.23.4";
    url = "https://files.pythonhosted.org/packages/6a/4d/23e390234d2acd351f5563b1079c515d7c1fe13ddb7392cee543be74dda3/tree_sitter_cpp-0.23.4-cp39-abi3-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
    hash = "sha256-dz0sr8CLvA+Zhof6M/QvN4waNxzbWChwxNE6uwYJJwY=";
  };
  tree-sitter-go = mkTreeSitterWheel {
    pname = "tree-sitter-go";
    grammarVersion = "0.25.0";
    url = "https://files.pythonhosted.org/packages/86/fb/b30d63a08044115d8b8bd196c6c2ab4325fb8db5757249a4ef0563966e2e/tree_sitter_go-0.25.0-cp310-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl";
    hash = "sha256-BLOzy0r/GOdOKNSbcWxvJMtx3f3WZ2iYfibk0PqBL3Q=";
  };
  tree-sitter-php = mkTreeSitterWheel {
    pname = "tree-sitter-php";
    grammarVersion = "0.24.1";
    url = "https://files.pythonhosted.org/packages/9a/c6/fd863a7a779d0ab67688939eba0e08bff7b1ffe731288d3d3610df21217b/tree_sitter_php-0.24.1-cp310-abi3-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl";
    hash = "sha256-ehQEow8pckmKzgQLAClzi42sRdChKTLMuLYF65S6++Q=";
  };
  tree-sitter-lua = mkTreeSitterWheel {
    pname = "tree-sitter-lua";
    grammarVersion = "0.5.0";
    url = "https://files.pythonhosted.org/packages/45/2b/1edfd9bef9a1cc11047cd87ca9c60707b8425080cfc0498a7d3bc762d783/tree_sitter_lua-0.5.0-cp310-abi3-manylinux1_x86_64.manylinux_2_28_x86_64.manylinux_2_5_x86_64.whl";
    hash = "sha256-XsRIyFT+oyQUoESRR9ZIvFut33oDVwCMSr4yads1Nwo=";
  };

  # lark-oapi (Feishu/Lark OpenAPI SDK) — not in nixpkgs.
  lark-oapi = python3Packages.buildPythonPackage {
    pname = "lark-oapi";
    version = "1.6.5";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/40/28/a425593c6de71b80ad642ed8e624468a2848ea0e4ad7cb32a8380941fd7f/lark_oapi-1.6.5-py3-none-any.whl";
      hash = "sha256-pW+lSK69rpw27wEU+7xuXQBOsuFTmOEc+IpXN/DPhkE=";
    };
    dependencies = with python3Packages; [
      requests
      requests-toolbelt
      pycryptodome
      protobuf
      websockets
      httpx
    ];
    # lark-oapi pins websockets<16; nixpkgs has 16.0.
    pythonRelaxDeps = [ "websockets" ];
    doCheck = false;
    meta.license = lib.licenses.mit;
  };

  # opentelemetry-instrumentation-asyncio — not packaged individually in
  # nixpkgs. Pinned to 0.55b0 to match nixpkgs' opentelemetry-* stack (the
  # wheel pins its siblings with ==; openviking's pythonRelaxDeps covers the
  # resulting "<0.61b0" gap against pyproject).
  opentelemetry-instrumentation-asyncio = python3Packages.buildPythonPackage {
    pname = "opentelemetry-instrumentation-asyncio";
    version = "0.55b0";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/82/71/64ed9dc18c278fd153a09af240c46dbbcf13244b76c256c9c6798c2faf1d/opentelemetry_instrumentation_asyncio-0.55b0-py3-none-any.whl";
      hash = "sha256-Mnj/iWSHfOFjiLuvZGV6pt+j5ewHF1WD7XINN89KVpE=";
    };
    dependencies = with python3Packages; [
      opentelemetry-api
      opentelemetry-instrumentation
      opentelemetry-semantic-conventions
      wrapt
    ];
    doCheck = false;
    meta.license = lib.licenses.asl20;
  };

  # Volcengine SDK — ByteDance cloud SDK (pure Python).
  volcengine = python3Packages.buildPythonPackage {
    pname = "volcengine";
    version = "1.0.217";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/28/ea/2801b15e71fc571404b8204bb5d0b80ca94d4e325e07a73848788cfa5d97/volcengine-1.0.217-py3-none-any.whl";
      hash = "sha256-PwBDcTwYtKFlf3aKyMNVBgkfAm1pgtkq+MHjf5OQb04=";
    };
    # "google>=3.0.0" is a misleading dep — volcengine uses google.protobuf.
    nativeBuildInputs = [ python3Packages.pythonRelaxDepsHook ];
    pythonRemoveDeps = [ "google" ];
    dependencies = with python3Packages; [
      protobuf
      pycryptodome
      pytz
      requests
      retry
      six
    ];
    doCheck = false;
    meta.license = lib.licenses.asl20;
  };

  volcengine-python-sdk = python3Packages.buildPythonPackage {
    pname = "volcengine-python-sdk";
    version = "5.0.16";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/87/f2/ebafb985b6bce5ecef36367be985e80dcd7f3f73d1fdd54c16a25a4a3d88/volcengine_python_sdk-5.0.16-py2.py3-none-any.whl";
      hash = "sha256-ioVWPzpI3FGiQ/6Xg14N5ZbhXtZ9O8Dw4+lS9TBRUfs=";
    };
    dependencies = with python3Packages; [
      certifi
      python-dateutil
      six
      urllib3
      # ark extra deps
      pydantic
      httpx
      anyio
      cryptography
    ];
    doCheck = false;
    meta.license = lib.licenses.asl20;
  };
in

python3Packages.buildPythonApplication {
  pname = "openviking";
  inherit version src;
  pyproject = true;

  env = {
    # setuptools-scm needs this — we build from a GitHub tarball, not a git
    # checkout. build_support/versioning.py also reads OPENVIKING_VERSION.
    SETUPTOOLS_SCM_PRETEND_VERSION = version;
    OPENVIKING_VERSION = version;
    # C++ vector-engine SIMD variants to build (x86_profiles.py always also
    # builds the sse3 baseline). avx2 covers the target hosts.
    OV_X86_BUILD_VARIANTS = "avx2";
    # ragfs_python is injected pre-built (see preBuild) — skip the maturin
    # build. OV_REQUIRE_RAGFS_BUILD=0 is required because the bdist_wheel
    # path otherwise treats a skipped ragfs artifact as a hard error.
    OV_SKIP_RAGFS_BUILD = "1";
    OV_REQUIRE_RAGFS_BUILD = "0";
  };

  postPatch = ''
    # Drop cmake + maturin from PEP 517 build-system requires — system cmake
    # is provided, and ragfs_python is injected pre-built (no maturin run).
    substituteInPlace pyproject.toml \
      --replace-fail '"cmake>=3.15",' "" \
      --replace-fail '"maturin>=1.0,<2.0",' ""
  '';

  preBuild = ''
    # Inject the pre-built ov CLI so setup.py skips the cargo build.
    mkdir -p prebuilt
    cp ${ov-cli}/bin/ov prebuilt/
    export OV_PREBUILT_BIN_DIR=$(pwd)/prebuilt

    # Inject the pre-built ragfs_python extension into openviking/lib/ so the
    # `lib/ragfs_python*.so` package-data glob bundles it into the wheel.
    # maturin installs it under a ragfs_python/ package directory.
    mkdir -p openviking/lib
    cp ${ragfs-python}/${python3Packages.python.sitePackages}/ragfs_python/ragfs_python*.so openviking/lib/
  '';

  build-system = with python3Packages; [
    setuptools
    setuptools-scm
    pybind11
    wheel
  ];

  # System cmake for the C++ pybind11 vector engine (invoked by setup.py).
  nativeBuildInputs = [ cmake ];
  dontUseCmakeConfigure = true;

  # pyproject.toml carries tight upstream version pins (e.g.
  # litellm<1.84.1, python-multipart>=0.0.27) that the nixpkgs package set
  # will not match exactly; relax them rather than chase each one.
  pythonRelaxDeps = true;

  # The vendored C++ uses -Wno-format, conflicting with NixOS hardening's
  # -Werror=format-security on GCC 15+.
  hardeningDisable = [ "format" ];

  dependencies =
    (with python3Packages; [
      # Core
      pydantic
      typing-extensions
      pyyaml
      httpx
      requests
      urllib3
      loguru
      cryptography
      argon2-cffi
      pathspec

      # LLM / AI
      openai
      litellm
      mcp

      # Server
      fastapi
      uvicorn
      python-multipart

      # Document parsing
      pdfplumber
      pdfminer-six
      python-docx
      python-pptx
      openpyxl
      olefile
      xlrd
      ebooklib
      readabilipy
      markdownify

      # Code parsing (tree-sitter)
      tree-sitter
      tree-sitter-python
      tree-sitter-javascript
      tree-sitter-rust
      tree-sitter-c-sharp

      # Observability
      opentelemetry-api
      opentelemetry-sdk
      opentelemetry-exporter-otlp-proto-grpc
      opentelemetry-exporter-otlp-proto-http

      # Utilities
      json-repair
      apscheduler
      xxhash
      jinja2
      tabulate
      protobuf
      typer
    ])
    ++ [
      # Tree-sitter grammars (pre-built wheels, not in nixpkgs).
      tree-sitter-typescript
      tree-sitter-java
      tree-sitter-cpp
      tree-sitter-go
      tree-sitter-php
      tree-sitter-lua

      # Other PyPI-wheel deps not in nixpkgs.
      lark-oapi
      opentelemetry-instrumentation-asyncio

      # Volcengine SDKs (packaged from PyPI wheels).
      volcengine
      volcengine-python-sdk

      # The Rust RAGFS PyO3 binding (also injected into openviking/lib/).
      ragfs-python
    ];

  # Tests require a running server + network + API keys.
  doCheck = false;

  # Confirm the native artifacts landed in the package.
  postInstall = ''
    site=$out/lib/python*/site-packages/openviking
    test -f $site/bin/ov || { echo "ERROR: ov binary not found in package" >&2; exit 1; }
    test -f "$(echo $site/lib/ragfs_python*.so)" || { echo "ERROR: ragfs_python extension not found in package" >&2; exit 1; }
  '';

  meta = {
    description = "OpenViking — agent-native context database for AI agents";
    homepage = "https://github.com/volcengine/OpenViking";
    license = lib.licenses.asl20;
    mainProgram = "openviking-server";
    platforms = lib.platforms.linux;
  };
}
