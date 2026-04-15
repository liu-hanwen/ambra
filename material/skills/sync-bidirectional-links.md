# Skill: Synchronize bidirectional links

## Purpose

Scan all layer content under the project root, detect missing reverse wikilinks in YAML front matter, and repair them automatically.

---

## Link Pairs

| Source field | Reverse field |
|---|---|
| `material.brief` | `brief.material` |
| `brief.knowledge` | `knowledge.briefs` |
| `knowledge.wisdoms` | `wisdom.knowledge` |

The script reads the source field and ensures the target file contains the reverse link.

---

## Prerequisites

- `python3`
- `pyyaml`

```bash
python3 -c "import yaml; print('pyyaml ok')" || pip3 install pyyaml
```

---

## Script Path

```text
material/skills/scripts/sync-bidirectional-links.py
```

---

## Usage

```bash
# Report missing reverse links without editing files
python3 material/skills/scripts/sync-bidirectional-links.py --dry-run --root .

# Fill in every missing reverse link
python3 material/skills/scripts/sync-bidirectional-links.py --root .
```

---

## Example Output

```text
Project root: /path/to/ambra
Mode: apply missing reverse links

  Updated: brief/source/item-name.md -> material += [[material/source/item-name]]
  Updated: knowledge/attention-mechanism.md -> briefs += [[brief/source/item-name]]

Completed 2 link repairs.
```

---

## Recommended Usage

1. Run it after each pipeline cycle.
2. Run it after creating or editing briefs, knowledge files, or wisdom files.
3. Use `--dry-run` before a commit when you want to inspect the pending repair set first.

---

## Behavior

- **Idempotent:** existing reverse links are not duplicated.
- **Additive only:** the script fills missing links but does not delete stale ones.
- **Graceful skip:** if the target file is missing, the script warns and continues.
- **Ignored files:** `AGENTS.md`, `memory.md`, and `tags.md` are excluded from scanning.
