# Agent Operating Guide

This repository is an authorized reverse-engineering and firmware-analysis workbench. The default agent runtime is `REA-opencode`, which includes OpenCode, REA, Ghidra, Java, JADX/APKTool, radare2, cross-architecture emulation/debugging tools, firmware unpackers, Python reverse-engineering libraries, and access to the local Qwen GGUF model through `REA-llm`.

## Runtime Facts

- Host project root on the main deployment: `/opt/examiner`
- Model endpoint inside Docker: `http://rea-llm:8080/v1`
- Host model endpoint: `http://127.0.0.1:12435/v1`
- Model id: `qwen3.8-27b-uncensored`
- OpenCode model id: `examiner-qwen/qwen3.8-27b-uncensored`
- REA MCP command: `rea mcp`
- OpenCode update helper inside the container: `update-opencode`
- OpenCode host update wrapper: `./update-opencode.sh`
- Ghidra install: `/opt/ghidra`
- Ghidra headless command: `/opt/ghidra/support/analyzeHeadless`
- Persistent specimen mount: `/data/specimens`
- Shared scratch workspace: `/workspace`

## Prime Directive

Work only on authorized targets. Treat specimens as potentially hostile and potentially sensitive. Default to static analysis. Do not execute unknown binaries, upload samples, contact public scanning services, or exfiltrate specimen-derived data unless the human explicitly authorizes that action.

## Primary Workflow

Work inside `/data/specimens/<case-name>` for real targets. Use `/workspace` only for generic scratch work or tooling experiments.

The human entry point is:

```bash
./shell.sh
```

It opens an interactive shell inside `REA-opencode` at `/data/specimens`.

Recommended case layout:

```text
/data/specimens/<case-name>/
  README.md
  originals/
  extracted/
  ghidra/
  notes/
  reports/
```

Create or maintain a case `README.md` with target description, source, authorization/scope notes, hashes, commands run, findings, and open questions.

## Evidence Rules

- Treat `originals/` as immutable.
- Never overwrite, strip, patch, unpack in place, or rename original specimens unless explicitly asked.
- Put derived files under `extracted/`, `ghidra/`, `notes/`, or `reports/`.
- Hash originals before deeper analysis when practical:

```bash
sha256sum originals/* > notes/originals.sha256
```

- Save important commands, versions, and observations in `notes/`.
- Use copies for destructive transforms.

## First-Pass Analysis

Start with metadata and static triage:

```bash
triage-specimen /data/specimens/<case-name>/originals/<target> /data/specimens/<case-name>
```

Then choose deeper tooling based on target type:

- ELF/PE/Mach-O: Ghidra, radare2, binutils, LLVM, angr, lief.
- APK/DEX/JAR: JADX, APKTool, Androguard, APKID, REA Android tools.
- Firmware: Binwalk, unblob, squashfs-tools, mtd-utils, u-boot-tools, device-tree-compiler.
- Disk or memory artifacts: sleuthkit, testdisk, volatility3.
- Raw ROMs/flat binaries: `analyze-raw-ghidra`, radare2, target disassemblers, known load address and CPU family.

## Ghidra Rules

Use the helper for normal binaries:

```bash
analyze-ghidra /data/specimens/<case-name>/originals/<target> <project-name>
```

Use the raw helper only when format headers are absent and the CPU/load address are known or reasonably inferred:

```bash
analyze-raw-ghidra originals/nes-prg.bin 6502:LE:16:default nes-prg 0x8000
analyze-raw-ghidra originals/z80.bin z80:LE:16:default z80-rom 0x0000
analyze-raw-ghidra originals/m68k.bin 68000:BE:32:default m68k-rom 0x000000
```

Keep Ghidra projects and exports under the case `ghidra/` folder whenever possible.

## OpenCode And REA

OpenCode is preconfigured to use the local llama.cpp model and REA MCP. Prefer REA tools when they provide structured binary-analysis state. Use raw CLI tools when they are clearer, faster, or easier to reproduce.

Useful checks:

```bash
opencode --version
rea doctor
rea mcp doctor
rea providers --json
```

`REA-opencode` refreshes OpenCode and REA packages on container startup when:

```text
OPENCODE_AUTO_UPDATE=1
```

Use this from the repo root for a live update:

```bash
./update-opencode.sh
```

Use this when the baked image itself should be rebuilt from configured package versions:

```bash
./update-opencode.sh rebuild
```

For reproducible cases, pin `OPENCODE_VERSION` and `REA_AGENTS_VERSION` in `.env`.

## Dynamic Analysis

Dynamic execution is not a default step.

Before dynamic analysis:

- Confirm the human wants execution/emulation.
- Prefer QEMU user/static or system emulation over host execution.
- Keep network disabled or isolated unless explicitly required.
- Document the exact command, environment, input files, and outputs.
- Run against copies under `extracted/`, not originals.

## Git Hygiene

Do not commit specimens, firmware, binaries, extracted case data, generated Ghidra projects, memory captures, strings, or final reports unless the human explicitly asks.

Allowed by default:

- Compose and Docker files
- Scripts
- Documentation
- Placeholder `.gitkeep` files
- Non-sensitive sample scaffolding

Ignored by design:

```text
models/*.gguf
data/specimens/*
```

## Verification

Before declaring stack changes complete, run:

```bash
docker compose config --quiet
docker compose ps
./scripts/smoke-test.sh
```

Expected:

- `REA-llm` responds to `/v1/models`.
- `REA` is healthy.
- `REA-opencode` starts.
- `opencode --version` works.
- Ghidra headless is present.
- REA MCP reports a healthy tool surface.
- Broad tooling is available, including `triage-specimen`, `analyze-raw-ghidra`, `qemu-aarch64-static`, `gdb-multiarch`, `unblob`, `llvm-objdump`, `z80dasm`, `ca65`, `ld65`, and `vol`.

## Documentation Contract

- Keep [README.md](./README.md) as the durable project overview.
- Keep [QUICKSTART.md](./QUICKSTART.md) as the shortest operator path.
- Keep this file focused on agent behavior and analysis rules.
- Keep [PLAN.md](./PLAN.md) as the implementation and hardening roadmap.
