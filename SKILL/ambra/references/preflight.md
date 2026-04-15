# Preflight

Read this before any initialization, ingestion, database, or pipeline workflow.

## Goal

Make sure the environment is viable before you try to bootstrap or run an Ambra vault.

## Core bootstrap checks

Run these checks first:

```bash
git --version
python3 --version
pip3 --version
sqlite3 --version
python3 -c "import yaml; print('pyyaml ok')"
```

## Ingestion and full-pipeline checks

Run these when the workflow will ingest content or run downstream processing:

```bash
pandoc --version
unzip -v >/dev/null 2>&1
```

## Required capabilities by workflow

### Required for every workflow

- `git` works
- `python3` works
- `pip3` is available for Python dependencies
- `sqlite3` works
- `python3` can import `yaml`

### Also required for ingestion-oriented workflows

These are required for:

- `ambra:add-source` when it will pull content immediately
- `ambra:search`
- `ambra:import`
- `ambra:run`
- `ambra:init` if the user wants a vault that is ready for immediate ingestion instead of just initial bootstrap

- `pandoc` works
- `unzip` works

## Optional dependencies

Only check these when the task needs them:

- `python3 -c "import bs4"` for HTML cleanup workflows
- `python3 -c "import readability"` for readability-based web extraction

## If the environment is not ready

Do not continue the workflow blindly.

1. Tell the user which dependency is missing.
2. Guide the user to install or configure it first.
3. Re-run the feasibility checks.
4. Proceed only after the environment is workable.

For `git clone git@github.com:liu-hanwen/ambra.git`, also make sure the user has working GitHub SSH access. If SSH access is not configured, guide the user to configure it before continuing.

## Shared runtime rules

- Run `./scripts/init-db.sh` before database work.
- Use `./scripts/sqlite.sh` for SQL access.
- Keep `queue.db` local and uncommitted.
- Run `python3 material/skills/scripts/sync-bidirectional-links.py --dry-run --root .` before concluding multi-file changes.

## Preflight checklist

- [ ] git works
- [ ] python3 works
- [ ] pip3 works
- [ ] sqlite3 works
- [ ] PyYAML is importable
- [ ] GitHub SSH access works if the workflow needs cloning
- [ ] pandoc works if this workflow will ingest content or run the full pipeline
- [ ] unzip works if this workflow will ingest content or run the full pipeline
- [ ] Missing dependencies, if any, were surfaced and resolved before proceeding
