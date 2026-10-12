# Agent Operating Guide

This repository is an authorized reverse-engineering and firmware-analysis workbench. The default agent runtime is `REA-opencode`, which includes OpenCode, REA, Ghidra, Java, JADX/APKTool, radare2, Python reverse-engineering libraries, and access to the local Qwen GGUF model through `REA-llm`.

## Runtime Facts

- Model endpoint inside Docker: `http://rea-llm:8080/v1`
- Model id: `qwen3.8-27b-uncensored`
- OpenCode model id: `examiner-qwen/qwen3.8-27b-uncensored`
- REA MCP command: `rea mcp`
- Ghidra install: `/opt/ghidra`
- Ghidra headless command: `/opt/ghidra/support/analyzeHeadless`
- Persistent specimen mount: `/data/specimens`
- Shared scratch workspace: `/workspace`

## Primary Workflow

Work inside `/data/specimens/<project-name>` whenever analyzing a real target. Use `/workspace` only for temporary scratch, generic tooling experiments, or outputs that are not tied to a specific case.

Recommended project layout:

```text
/data/specimens/<project-name>/
  README.md
  originals/
  extracted/
  ghidra/
  notes/
  reports/
```

Create a project `README.md` before or during first triage. It should record the target description, source, scope, authorization notes, hashes of original files, commands run, important findings, and open questions.

## Evidence Rules

- Treat files under `originals/` as immutable evidence.
- Do not overwrite, patch, strip, unpack in place, or rename original specimens unless the user explicitly asks.
- Put derived files in `extracted/`, `ghidra/`, `notes/`, or `reports/`.
- Record hashes before analysis when practical:

```bash
sha256sum originals/* > notes/originals.sha256
```

- Prefer repeatable commands and save important command transcripts or summaries in `notes/`.
- If a tool mutates a file, run it on a copy under `extracted/`.

## REA and Ghidra

Use REA first when it can answer the question through MCP or CLI. It exposes the intended agent tool surface and keeps analysis results structured.

Useful checks:

```bash
rea mcp doctor
rea doctor
rea providers --json
```

Use Ghidra headless for batch import/decompile workflows:

```bash
analyze-ghidra /data/specimens/<project-name>/originals/<target> <project-name>
```

For direct Ghidra invocation, keep projects and output under the project folder, preferably `ghidra/`.

## Android and Managed Targets

For APKs, start with static inspection:

```bash
apktool d originals/app.apk -o extracted/apktool
jadx -d extracted/jadx originals/app.apk
```

Use REA's Android commands when a structured agent workflow is better than raw CLI output.

For PE/.NET, keep metadata extraction and decompiler outputs under `extracted/` or `notes/`. Do not execute unknown binaries inside the analysis container unless the user explicitly authorizes dynamic execution and the risks are understood.

## Safety and Scope

- Assume specimens may be hostile.
- Do not execute unknown binaries as a default analysis step.
- Prefer static analysis, metadata extraction, string search, unpacking, and decompilation first.
- Do not contact external services with specimen data unless the user explicitly authorizes it.
- Do not upload samples, hashes, strings, firmware fragments, or reports to public services.
- Keep proprietary tools optional. Hopper and IDA are not bundled; use them only when the user provides licensed installs/configuration.

## Git Hygiene

Specimen contents are intentionally ignored by Git:

```text
data/specimens/*
```

Do not force-add binaries, firmware, case data, extracted files, or generated Ghidra projects without explicit user approval. It is okay to commit documentation, scripts, Compose files, and placeholder files.

## Verification

Before declaring the stack ready after changes, run:

```bash
docker compose config --quiet
docker compose ps
docker exec REA-opencode opencode --version
docker exec REA-opencode rea mcp doctor
curl -fsS http://127.0.0.1:12435/v1/models
```

Expected REA MCP result: healthy, 170 tools, 6 prompts.
