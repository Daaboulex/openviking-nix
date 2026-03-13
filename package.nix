# OpenViking — agent-native context database for AI agents
# Python package with embedded C++17 pybind11 vector engine, plus pre-built
# Go (AGFS) and Rust (ov CLI) native artifacts.
#
# Volcengine SDK dependencies are removed — they're only needed for ByteDance's
# cloud LLM/embedding endpoints. Configure OpenAI-compatible endpoints instead
# (works with Claude, OpenAI, Ollama, LiteLLM, etc.).
{
  lib,
  python3Packages,
  cmake,
  src,
  version,
  agfs,
  ov-cli,
}:

let
  # Helper to package tree-sitter grammar Python bindings missing from nixpkgs.
  # These compile grammar C source into a shared library + Python Language class.
  mkTreeSitterGrammar =
    {
      pname,
      grammarVersion,
      hash,
    }:
    python3Packages.buildPythonPackage {
      inherit pname;
      version = grammarVersion;
      src = python3Packages.fetchPypi {
        inherit pname hash;
        version = grammarVersion;
      };
      build-system = [ python3Packages.setuptools ];
      dependencies = [ python3Packages.tree-sitter ];
      doCheck = false;
      meta.license = lib.licenses.mit;
    };

  # TODO: replace hashes with real values after first build attempt
  tree-sitter-typescript = mkTreeSitterGrammar {
    pname = "tree-sitter-typescript";
    grammarVersion = "0.23.2";
    hash = lib.fakeHash;
  };
  tree-sitter-java = mkTreeSitterGrammar {
    pname = "tree-sitter-java";
    grammarVersion = "0.23.5";
    hash = lib.fakeHash;
  };
  tree-sitter-cpp = mkTreeSitterGrammar {
    pname = "tree-sitter-cpp";
    grammarVersion = "0.23.4";
    hash = lib.fakeHash;
  };
  tree-sitter-go = mkTreeSitterGrammar {
    pname = "tree-sitter-go";
    grammarVersion = "0.23.4";
    hash = lib.fakeHash;
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
    # Remove Volcengine SDK dependencies — only needed for Volcengine cloud backend.
    # Users should configure OpenAI-compatible endpoints (Claude, OpenAI, Ollama, etc.)
    substituteInPlace pyproject.toml \
      --replace-fail '"volcengine>=1.0.216",' "" \
      --replace-fail '"volcengine-python-sdk[ark]>=5.0.3",' ""

    # Remove cmake from PEP 517 build-system requires — we provide system cmake
    substituteInPlace pyproject.toml \
      --replace-fail '"cmake>=3.15",' ""
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

  # System cmake for the C++ pybind11 vector engine build
  nativeBuildInputs = [ cmake ];

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
      # Tree-sitter grammars packaged above (not in nixpkgs)
      tree-sitter-typescript
      tree-sitter-java
      tree-sitter-cpp
      tree-sitter-go
    ];

  # Tests require a running server + network + API keys
  doCheck = false;

  # Ensure the ov binary wrapper can find the embedded Rust binary
  postInstall = ''
    # Verify native artifacts were included in the package
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
