# Quickstart

This is the fast path for a new Binary Doctor machine.

## 1. Prepare Environment

```bash
cp .env.example .env
```

Optional edits in `.env`:

```text
HF_TOKEN=
LLM_PORT=12435
LLM_CTX_SIZE=262144
OPENCODE_AUTO_UPDATE=1
OPENCODE_VERSION=latest
REA_AGENTS_VERSION=latest
```

## 2. Fetch The GGUF

```bash
./scripts/fetch-weights.sh
```

The default model path is:

```text
./models/Qwen3.8-27B-Uncensored-Q4_K_M.gguf
```

If the model is already present, the script leaves it alone.

## 3. Build And Start

```bash
docker compose up -d --build
```

Check status:

```bash
docker compose ps
curl -fsS http://127.0.0.1:12435/v1/models | jq .
```

## 4. Enter The Workbench

```bash
./shell.sh
```

This opens a shell inside `REA-opencode` at:

```text
/data/specimens
```

## 5. Create A Case Folder

Inside the shell:

```bash
mkdir -p my-case/{originals,extracted,ghidra,notes,reports}
```

Put target files under:

```text
data/specimens/my-case/originals/
```

Then record hashes:

```bash
sha256sum my-case/originals/* > my-case/notes/originals.sha256
```

## 6. Run First Triage

```bash
triage-specimen my-case/originals/target.bin my-case
```

For APKs:

```bash
apktool d my-case/originals/app.apk -o my-case/extracted/apktool
jadx -d my-case/extracted/jadx my-case/originals/app.apk
```

For firmware:

```bash
binwalk -Me my-case/originals/firmware.bin -C my-case/extracted/binwalk
unblob my-case/originals/firmware.bin -o my-case/extracted/unblob
```

## 7. Use Ghidra

Normal import:

```bash
analyze-ghidra my-case/originals/target.bin my-case
```

Raw ROM or flat binary:

```bash
analyze-raw-ghidra my-case/originals/rom.bin 6502:LE:16:default my-rom 0x8000
```

## 8. Use OpenCode With REA

Inside `./shell.sh`:

```bash
opencode
```

The configured model is:

```text
examiner-qwen/qwen3.8-27b-uncensored
```

REA MCP is enabled through:

```text
rea mcp
```

## 9. Update OpenCode

Live update:

```bash
./update-opencode.sh
```

Rebuild the image with latest OpenCode and REA packages:

```bash
./update-opencode.sh rebuild
```

## 10. Smoke Test

```bash
./scripts/smoke-test.sh
```

Use this after builds, dependency changes, or moving the repo to a new host.
