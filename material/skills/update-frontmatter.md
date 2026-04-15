# Skill: Update YAML front matter with Python

## Purpose

Use the shared Python helper to read and write YAML front matter reliably. This avoids brittle shell-level YAML edits and keeps wikilinks, Unicode text, and empty-list handling consistent.

---

## Prerequisites

- `python3`
- `pyyaml` (`pip3 install pyyaml` if needed)

Check availability:

```bash
python3 -c "import yaml; print('pyyaml ok')" || pip3 install pyyaml
```

---

## Script Path

```text
material/skills/scripts/update-frontmatter.py
```

---

## Usage

```bash
# Overwrite a field
python3 material/skills/scripts/update-frontmatter.py <file> set <field> <value>

# Append one value to a list field without duplicating it
python3 material/skills/scripts/update-frontmatter.py <file> append <field> <value>
```

---

## Common Examples

### Set `material.brief`

```bash
python3 material/skills/scripts/update-frontmatter.py \
  "material/source/item-name.md" set brief "[[brief/source/item-name]]"
```

### Append to `brief.knowledge`

```bash
python3 material/skills/scripts/update-frontmatter.py \
  "brief/source/item-name.md" append knowledge "[[knowledge/attention-mechanism]]"
```

### Append to `knowledge.briefs`

```bash
python3 material/skills/scripts/update-frontmatter.py \
  "knowledge/attention-mechanism.md" append briefs "[[brief/source/item-name]]"
```

### Append to `knowledge.wisdoms`

```bash
python3 material/skills/scripts/update-frontmatter.py \
  "knowledge/attention-mechanism.md" append wisdoms "[[wisdom/transformer-overview]]"
```

### Append to `wisdom.knowledge`

```bash
python3 material/skills/scripts/update-frontmatter.py \
  "wisdom/transformer-overview.md" append knowledge "[[knowledge/attention-mechanism]]"
```

---

## Behavior

| Operation | Existing scalar | Existing list | Missing field |
|---|---|---|---|
| `set` | replace it | replace it | create it |
| `append` | convert to a two-item list | append if missing | create a one-item list |

- **Idempotent:** `append` never duplicates the same value.
- **Unicode-safe:** the helper preserves non-ASCII text instead of escaping it into `\uXXXX`.
- **Body-safe:** only front matter changes; the Markdown body stays untouched.

---

## Why not use `yq` for writes

Shell-level `yq` edits are brittle when:

- YAML values include non-ASCII text
- fields contain wikilinks like `[[...]]`
- empty lists and `null` values behave differently across versions

Python + PyYAML is more predictable for this repository's front matter conventions.
