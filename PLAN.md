# Binary Doctor Plan

This plan tracks the intended shape of the project and the next hardening steps.

## Current State

Implemented:

- Docker Compose stack with separate model fetch, model server, REA workbench, and OpenCode runtime services.
- Direct llama.cpp `llama-server` GGUF serving with CUDA, OpenAI-compatible API, full-context configuration, flash attention, Jinja chat-template support, and reasoning preservation.
- Qwen 3.8 27B Uncensored GGUF fetch path through `./scripts/fetch-weights.sh` and `REA-model-fetch`.
- REA image containing REA, OpenCode, Ghidra, Java, JADX/APKTool, radare2, firmware tools, archive tools, emulation/debugging tools, Python RE libraries, and broad architecture support.
- ARM64 support with native Ghidra decompiler compilation during image build.
- x64 support using Ghidra's bundled Linux x86_64 decompiler.
- Persistent case workspace at `./data/specimens`.
- Operator shell wrapper at `./shell.sh`.
- OpenCode auto-update path through `REA-opencode`, `update-opencode`, and `./update-opencode.sh`.
- Smoke test script at `./scripts/smoke-test.sh`.
- Raw binary/ROM helper at `analyze-raw-ghidra`.

Validated on the GB10 deployment:

- `REA-llm` responds at `/v1/models`.
- Model id is `qwen3.8-27b-uncensored`.
- Context metadata reports `262144`.
- `REA` and `REA-opencode` containers start.
- OpenCode runs inside `REA-opencode`.
- Ghidra headless and ARM64 native decompiler are available.
- Broad toolchain smoke test passes.

## Near-Term Hardening

1. Add version pin sets.

   Keep `latest` convenient for fast moving OpenCode/REA work, but add an example `.env.pinned` or documented lock profile for repeatable forensic cases.

2. Add build profiles.

   Suggested profiles:

   - `gb10-arm64`: GB10/DGX Spark class machines.
   - `cuda-x64`: x64 NVIDIA hosts.
   - `cpu-dev`: CPU-only documentation and config validation path.

3. Improve model runtime tuning.

   Test and document:

   - `LLM_THREADS`
   - `LLM_BATCH`
   - `LLM_UBATCH`
   - `LLM_PARALLEL`
   - CUDA architecture flags
   - long-context stability under REA/OpenCode tool use

4. Add case template generator.

   Create a script such as:

   ```bash
   ./scripts/new-case.sh case-name
   ```

   It should create the standard folder layout and a starter case `README.md`.

5. Add sample fixtures.

   Add tiny non-sensitive test binaries or generated fixtures for:

   - ELF x86_64
   - ELF ARM
   - PE
   - APK stub
   - raw 6502 or z80 blob
   - compressed firmware-like archive

   Keep them small and clearly synthetic.

6. Add CI-style validation.

   At minimum:

   - `docker compose config --quiet`
   - shellcheck for scripts
   - documentation link check
   - Dockerfile parse/build smoke where feasible

## Tooling Improvements

- Add a richer `triage-specimen` report index.
- Add optional SBOM generation for extracted firmware.
- Add a `case-summary` helper that collects hashes, tool versions, key outputs, and notes into one Markdown report.
- Add a `list-ghidra-languages` helper for raw ROM workflows.
- Add optional YARA rule update path that does not upload specimens.
- Add optional offline mode documentation for air-gapped analysis.

## Security Hardening

- Keep default analysis static.
- Review Linux capabilities and remove any that are not required.
- Add a stricter dynamic-analysis profile with no external network.
- Document when `SYS_PTRACE` is required.
- Consider read-only mounts for `originals/` once a case is created.
- Add warnings for commands that execute target code.

## Proprietary Tool Integration

Hopper is intentionally not bundled. Current path:

```text
/opt/hopper
```

Future optional integrations:

- Hopper detection helper.
- IDA MCP configuration hook.
- Binary Ninja external mount hook.

These should remain optional and documented as licensed tools supplied by the operator.

## Release Checklist

Before tagging or publishing a release:

```bash
docker compose config --quiet
docker compose up -d --build
./scripts/smoke-test.sh
./update-opencode.sh
git status --short
```

Check docs:

- README reflects current services and ports.
- QUICKSTART works on a fresh machine.
- AGENTS reflects current safety rules.
- PLAN reflects completed and remaining work.

Check repository contents:

- No GGUF weights.
- No specimens.
- No generated Ghidra projects.
- No private tokens.
- No machine-local secrets.
