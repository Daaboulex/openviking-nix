# OpenViking — agent-native context database for AI agents
# Python package with embedded C++17 pybind11 vector engine, plus pre-built
# Go (AGFS) and Rust (ov CLI) native artifacts.
{
  lib,
  python3Packages,
  fetchurl,
  cmake,
  src,
  version,
  agfs,
  ov-cli,
}:

let
  # Tree-sitter grammar Python bindings missing from nixpkgs.
  # Use pre-built manylinux wheels to avoid ABI mismatch between grammar C source
  # (generated for tree-sitter 0.23.x) and nixpkgs' tree-sitter 0.25.x parser.h.
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

  # Volcengine SDK — ByteDance cloud SDK (pure Python)
  volcengine = python3Packages.buildPythonPackage {
    pname = "volcengine";
    version = "1.0.217";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/28/ea/2801b15e71fc571404b8204bb5d0b80ca94d4e325e07a73848788cfa5d97/volcengine-1.0.217-py3-none-any.whl";
      hash = "sha256-PwBDcTwYtKFlf3aKyMNVBgkfAm1pgtkq+MHjf5OQb04=";
    };
    # "google>=3.0.0" is a misleading dep — volcengine uses google.protobuf from protobuf
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
    # setuptools-scm needs this since we build from a GitHub tarball, not a git checkout
    SETUPTOOLS_SCM_PRETEND_VERSION = version;
    # SIMD level for the C++ vector engine (AVX2 = safe default, NATIVE = max perf)
    OV_X86_SIMD_LEVEL = "AVX2";
  };

  postPatch = ''
    # Remove cmake from PEP 517 build-system requires — we provide system cmake
    substituteInPlace pyproject.toml \
      --replace-fail '"cmake>=3.15",' ""

    # Relax python-multipart version (nixpkgs has 0.0.21, project requires >= 0.0.22)
    substituteInPlace pyproject.toml \
      --replace-fail '"python-multipart>=0.0.22",' '"python-multipart>=0.0.20",'
  '';

  preBuild = ''
    # Inject pre-built native artifacts so setup.py skips Go/Rust compilation
    mkdir -p prebuilt
    cp ${agfs}/bin/agfs-server prebuilt/
    cp ${agfs}/lib/libagfsbinding.so prebuilt/
    cp ${ov-cli}/bin/ov prebuilt/
    export OV_PREBUILT_BIN_DIR=$(pwd)/prebuilt
  '';

  build-system = with python3Packages; [
    setuptools
    setuptools-scm
    pybind11
    wheel
  ];

  # System cmake for the C++ pybind11 vector engine build (invoked by setup.py, not directly)
  nativeBuildInputs = [ cmake ];
  dontUseCmakeConfigure = true;

  # The vendored C++ code uses -Wno-format which conflicts with NixOS hardening's
  # -Werror=format-security on GCC 15+
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

      # LLM / AI
      openai
      litellm

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
      ebooklib
      readabilipy
      markdownify

      # Code parsing (tree-sitter)
      tree-sitter
      tree-sitter-python
      tree-sitter-javascript
      tree-sitter-rust
      tree-sitter-c-sharp

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
      # Tree-sitter grammars (pre-built wheels, not in nixpkgs)
      tree-sitter-typescript
      tree-sitter-java
      tree-sitter-cpp
      tree-sitter-go

      # Volcengine SDKs (packaged from PyPI wheels)
      volcengine
      volcengine-python-sdk
    ];

  # Tests require a running server + network + API keys
  doCheck = false;

  # Ensure native artifacts were included in the package
  postInstall = ''
    site=$out/lib/python*/site-packages/openviking
    test -f $site/bin/ov || echo "WARNING: ov binary not found in package"
    test -f $site/bin/agfs-server || echo "WARNING: agfs-server not found in package"
    test -f $site/lib/libagfsbinding.so || echo "WARNING: libagfsbinding.so not found in package"
  '';

  meta = {
    description = "OpenViking — agent-native context database for AI agents";
    homepage = "https://github.com/volcengine/OpenViking";
    license = lib.licenses.asl20;
    mainProgram = "openviking-server";
    platforms = lib.platforms.linux;
  };
}
