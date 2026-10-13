# Examiner REA Stack

`/opt/examiner` is a portable reverse-engineering stack for authorized binary, firmware, mobile, memory, and archive analysis.

It keeps the model fetcher, model server, analysis workbench, and OpenCode runtime separate:

- `model-fetch`: downloads the Qwen GGUF into repo-local `./models` if it is not already present.
- `REA-llm`: direct `llama-server` built for NVIDIA CUDA, serving the existing Qwen 3.8 27B Uncensored GGUF over an OpenAI-compatible API.
- `REA`: REA, Ghidra, Java, Node.js, Python RE libraries, and common static/dynamic analysis tools.
- `REA-opencode`: preconfigured OpenCode runtime using the same fully tooled REA image, pointed at `REA-llm`, with REA MCP enabled.
- `./data/specimens`: persistent host-side specimen and case workspace, mounted into containers at `/data/specimens`.

## Start

```bash
cd /opt/examiner
cp .env.example .env
docker compose up -d --build
```

On a fresh machine, `docker compose up -d --build` will build the containers and download the configured GGUF into `./models`. If you want to pull the weights explicitly first:

```bash
./scripts/fetch-weights.sh
```

The model endpoint will be:

```text
http://gx10:12435/v1
```

The stable model id is:

```text
qwen3.8-27b-uncensored
```

The OpenAI-compatible endpoint is:

```text
http://localhost:12435/v1
```

Inside Compose, services use:

```text
http://rea-llm:8080/v1
```

## Specimen Workspace

Use `./data/specimens` for real analysis projects. It persists outside Docker and is mounted read-write into both `REA` and `REA-opencode`:

```text
host:      ./data/specimens
container: /data/specimens
```

Create one subfolder per project or case:

```bash
mkdir -p data/specimens/project-name/{originals,extracted,ghidra,notes,reports}
```

Recommended use:

- `originals/`: source artifacts kept immutable, such as firmware, binaries, APKs, archives, disk images, memory captures, and vendor packages.
- `extracted/`: unpacked or decoded artifacts created during analysis.
- `ghidra/`: Ghidra projects, decompiler output, symbols, and headless-analysis exports.
- `notes/`: working notes, triage logs, commands, hypotheses, and indicators.
- `reports/`: polished findings and handoff material.

Specimen contents are ignored by Git by default. Keep the project README, hashes, and case notes under the project folder, but be deliberate before committing any specimen-derived material.

To enter the prepared analysis shell directly:

```bash
./shell.sh
```

That lands inside `REA-opencode` at `/data/specimens`, with REA/Ghidra/model environment variables loaded and a short reminder of the case folder layout.

## OpenCode

The repo includes a preconfigured OpenCode runtime container. It uses the same image as `REA`, so local MCP tools can see REA, Ghidra, Java, JADX/APKTool, and the rest of the analysis toolchain.

Interactive shell:

```bash
docker exec -it REA-opencode bash
cd /data/specimens/project-name
```

Run OpenCode directly:

```bash
docker exec -it REA-opencode opencode
```

The default OpenCode config is mounted from:

```text
./opencode/opencode.json
```

It points at:

```text
examiner-qwen/qwen3.8-27b-uncensored
```

REA MCP is enabled in that same config:

```text
rea mcp
```

An OpenCode v2-shaped config is also included at `./opencode/opencode-v2.json`.

## First-Pass Triage

Use `triage-specimen` before deeper work. It is static-only by default and writes a Markdown report plus extracted string files:

```bash
docker exec -it REA triage-specimen /data/specimens/project-name/originals/firmware.bin /data/specimens/project-name
```

The triage helper records hashes, file metadata, ExifTool output, Binwalk signatures, ELF/PE quick checks, baseline YARA hits, and ASCII/UTF-16 string output. For APK/JAR/DEX targets, it also runs JADX/APKTool into the project `extracted/` folder.

## Tools Included

- REA: installed from the `rea-agents` npm package.
- OpenCode: installed from `opencode-ai`, with the default model set to the local Qwen GGUF server.
- Ghidra: installed under `/opt/ghidra`; headless entry point is `/opt/ghidra/support/analyzeHeadless`.
- Java: default JDK from Ubuntu 24.04.
- Android/static app RE: `jadx`, `apktool`, `adb`.
- Static RE: `file`, `binutils`, `elfutils`, `radare2`, `capstone`, `yara`, `binwalk`, `exiftool`, `ripgrep`, `xxd`, `srecord`.
- Firmware/filesystem unpacking: `binwalk`, `unblob`, `squashfs-tools`, `mtd-utils`, `u-boot-tools`, `device-tree-compiler`, `sleuthkit`, `testdisk`, `foremost`, `libarchive-tools`.
- Archive/compression conversion: `7z`, `unar`, `arj`, `lhasa`, `xz`, `zstd`, `lz4`, `lzip`, `lzop`, `brotli`, `gzip`, `bzip2`, `cpio`, `zip`, `unzip`.
- Cross-architecture emulation/debugging: `qemu-user`, `qemu-user-static`, `qemu-system`, `qemu-utils`, `gdb`, `gdb-multiarch`, `strace`, `ltrace`.
- Managed and mobile analysis: `jadx`, `apktool`, `androguard`, `apkid`, `oletools`, `dnfile`, `macholib`.
- Malware triage helpers: `flare-floss`, baseline local YARA rules under `/opt/yara-rules`, `john`, `nmap`.
- Python RE: `angr`, `lief`, `pwntools`, `r2pipe`, `ghidra-bridge`, `volatility3`, `yara-python`, `pefile`, `pyelftools`, `unicorn`, `ropper`, `smda`, `python-magic`.

## Ghidra Headless

Ghidra's supported batch interface is `analyzeHeadless`. A helper is included:

```bash
docker exec -it REA analyze-ghidra /data/specimens/project-name/originals/firmware.bin firmware-project
```

Outputs land in the mounted workspace unless the tool or project folder specifies a more specific output path.

## REA

Run:

```bash
docker exec -it REA rea-doctor
docker exec -it REA rea doctor
docker exec -it REA-opencode rea mcp doctor
docker exec -it REA triage-specimen /data/specimens/project-name/originals/target.bin /data/specimens/project-name
```

The container image bakes in REA's bundled reverse-engineering skill. The OpenCode container mounts `./opencode/opencode.json`, which registers REA's local MCP server as `rea`.

## Hopper

Hopper is proprietary. This image does not redistribute it. If you have a licensed Linux Hopper install, place or mount it at:

```text
/opt/hopper
```

The `REA` container mounts that path read-only. REA can then detect/use Hopper if its installed CLI/GUI paths are compatible.

## Model Serving Notes

This stack avoids Docker Model Runner and Ollama. It builds upstream `llama.cpp` directly with:

- CUDA enabled
- multi-platform Docker support for `linux/arm64` and `linux/amd64`
- CUDA architecture `121` by default on ARM64 GB10 / DGX Spark class machines
- CUDA architectures `75;80;86;89;90` by default on x64 NVIDIA hosts
- `llama-server` OpenAI-compatible HTTP API
- full 262144-token context by default
- flash attention
- Jinja chat template handling
- reasoning preservation
- one long-context slot by default
- a stable API alias: `qwen3.8-27b-uncensored`

For agentic binary analysis, `LLM_PARALLEL=1` is the conservative starting point. Increase it only if you need concurrent users and can tolerate less effective KV/cache room per request.

Set `LLAMA_CUDA_ARCHS` in `.env` if you want a narrower or newer x64 CUDA build, for example `LLAMA_CUDA_ARCHS=89` for Ada-only, or a semicolon-separated list for a reusable image. `GGML_NATIVE=OFF` is the portable default; set it to `ON` only when building and running on the same CPU family.

## Portability Notes

The repo is intended to be pushed to a private GitHub repository without the model weights. `./models/*.gguf` is ignored by Git. A new host can clone the repo, run `cp .env.example .env`, optionally set `HF_TOKEN`, then run:

```bash
docker compose up -d --build
```

The only large external artifact pulled at runtime is the GGUF. Ghidra, REA, Java, Python tooling, llama.cpp, and OpenCode are built into containers.

Specimens under `./data/specimens/*` are ignored by Git by default. Copy or sync them separately when moving between machines, unless you intentionally create a private evidence repository with the proper access controls.

Hopper and IDA remain optional and external because they are proprietary/licensed. Mount a compatible licensed Linux Hopper installation at `/opt/hopper` on the host if you want REA to use it. If you later add IDA MCP, provide its registration JSON and set `REA_IDA_MCP_CONFIG` explicitly.

For x64 hosts, Ghidra uses the upstream bundled `linux_x86_64` native decompiler. For ARM64 hosts, the Docker build compiles Ghidra's included decompiler source into `linux_arm_64/decompile`.

## Sources Used

- REA documentation says REA is distributed as `rea-agents`, supports MCP/CLI, and uses existing Ghidra/Hopper installations.
- Ghidra documentation identifies `analyzeHeadless` as the supported command-line analyzer for importing, processing, scripting, and batch analysis.
- The Qwen GGUF model card exposes the existing GGUF layout and llama.cpp usage path.
- Current GB10 guidance points at direct llama.cpp builds for `sm_121` when serving GGUF efficiently.
