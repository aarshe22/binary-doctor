# Specimens Directory

This directory is mounted into the containers at:

```text
/data/specimens
```

Use one subdirectory per investigation, assessment, firmware image, appliance, vendor package, or case.

Recommended layout:

```text
data/specimens/
  project-name/
    README.md
    originals/
    extracted/
    ghidra/
    notes/
    reports/
```

- `originals/`: immutable source artifacts. Put firmware, binaries, APKs, archives, disk images, memory captures, and vendor packages here.
- `extracted/`: unpacked firmware, filesystem extractions, decoded APK resources, carved files, and derived artifacts.
- `ghidra/`: Ghidra project exports, headless-analysis scratch output, symbol exports, and decompiler artifacts.
- `notes/`: working notes, hypotheses, triage logs, indicators, and command transcripts.
- `reports/`: polished findings, summaries, evidence tables, and handoff material.

The repo ignores specimen contents by default so binaries and case data are not accidentally committed.

Inside containers, refer to this directory as `/data/specimens`, for example:

```bash
docker exec -it REA-opencode bash
cd /data/specimens/project-name
```

For repeatability, create a short `README.md` inside every project folder that records:

- What the specimen is and where it came from.
- Hashes of original files.
- Scope and authorization notes.
- Commands or tools already run.
- Important findings and open questions.
