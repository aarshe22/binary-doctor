# Dependency Checkouts

This directory is for optional local Git dependency checkouts managed by:

```bash
./update-deps.sh
```

The cloned repositories themselves are ignored by Git. The tracked file is `repos.tsv`, which records the dependency name, Git URL, ref, and local path.

Current dependency:

- `llama.cpp`: source dependency used by the `REA-llm` Docker image. The Docker build can still clone it directly from GitHub, but this local checkout gives operators a clear way to pull, inspect, pin, and audit the source dependency used by the stack.

Refs can use environment expansion. For example, the default `llama.cpp` ref is:

```text
${LLAMA_CPP_REF:-master}
```

Set `LLAMA_CPP_REF` in `.env` to a branch, tag, or commit SHA when you need a repeatable build.
