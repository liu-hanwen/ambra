# Skill: EPUB to Markdown (split by chapter)

## Purpose

Convert an EPUB into chapter-level Markdown files while keeping the book structure intact.

---

## Prerequisites

- `pandoc` >= 2.x
- `unzip`

Check availability:

```bash
pandoc --version && unzip -v
```

---

## Steps

### Step 1: inspect the EPUB structure

```bash
unzip -l "input/{file}.epub" | grep -E "\\.xhtml|\\.html|\\.ncx|\\.opf"
```

Use this to confirm the source chapter order and internal packaging.

### Step 2: convert the full book into one Markdown file

```bash
pandoc -f epub -t markdown \
  --wrap=none \
  --extract-media="material/{source}/{slug}/media" \
  -o "/tmp/{slug}-full.md" \
  "input/{file}.epub"
```

`--extract-media` writes images into a dedicated `media/` directory and updates relative paths in the Markdown.

### Step 3: split by chapter

```bash
bash material/skills/scripts/split-epub-chapters.sh \
  "/tmp/{slug}-full.md" \
  "material/{source}/{slug}/"
```

Output files follow the pattern `c01-chapter-name.md`, `c02-chapter-name.md`, and so on.

### Step 4: validate completeness

```bash
SPINE_COUNT=$(unzip -p "input/{file}.epub" "*content.opf" 2>/dev/null | grep -c '<itemref' || echo 0)
SPLIT_COUNT=$(ls "material/{source}/{slug}/"c[0-9]*.md 2>/dev/null | wc -l)

echo "EPUB spine items: ${SPINE_COUNT}; split chapter files: ${SPLIT_COUNT}"

if [[ "$SPINE_COUNT" -gt 0 && "$SPLIT_COUNT" -lt "$SPINE_COUNT" ]]; then
  echo "WARNING: the EPUB contains ${SPINE_COUNT} spine documents, but only ${SPLIT_COUNT} chapter files were produced."
  echo "The likely cause is that some sections were merged because they did not start with an H1 heading."
  echo "Inspect /tmp/{slug}-full.md and repair chapter boundaries if needed."
fi

for f in "material/{source}/{slug}/"c[0-9]*.md; do
  if [[ ! -s "$f" ]]; then
    echo "WARNING: empty chapter file detected: $f"
  fi
done
```

If chapters are missing, try splitting on H2 boundaries or repair the full Markdown manually.

---

## Outputs

- directory: `material/{source}/{slug}/`
- chapter files: `c01-chapter-name.md`, `c02-chapter-name.md`, ...
- media files: `material/{source}/{slug}/media/`

Front matter is added later by the material agent.

---

## Notes

- If the chapter count exceeds 99, switch to prefixes such as `c001-` to preserve sort order.
- Replace spaces and other unsafe characters in chapter names with hyphens.
- If the book has no useful chapter structure, fall back to a single file such as `material/{source}/{slug}.md`.
- Keep the original EPUB.
