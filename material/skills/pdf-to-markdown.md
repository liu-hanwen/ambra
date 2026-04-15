# Skill: PDF to Markdown

## Purpose

Convert a PDF into Markdown while preserving as much document structure as possible.

---

## Prerequisites

- `pandoc` (preferred) or `pdftotext` from `poppler-utils`
- a real text PDF rather than an image-only scan

Check availability:

```bash
pandoc --version || pdftotext -v
```

---

## Steps

### Option A: use `pandoc`

```bash
pandoc -f pdf -t markdown \
  --wrap=none \
  -o "output/{slug}.md" \
  "input/{file}.pdf"
```

Notes:

- `--wrap=none` keeps paragraph boundaries intact.
- output filenames should use stable lowercase slugs.

### Option B: use `pdftotext` first

```bash
pdftotext -layout "input/{file}.pdf" "/tmp/{slug}.txt"
pandoc -f plain -t markdown --wrap=none -o "output/{slug}.md" "/tmp/{slug}.txt"
```

### Structured PDFs with chapters or bookmarks

Inspect metadata and outlines if present:

```bash
pdfinfo "input/{file}.pdf"
```

Try to preserve the heading hierarchy as Markdown headings. If the converter misses major section boundaries, repair them manually or with an LLM pass.

---

## Outputs

- Markdown file: `material/{source}/{slug}.md`
- front matter is added by the calling material agent, not by this skill

---

## Integrity Checks

After conversion, confirm that the output is not obviously incomplete:

```bash
OUTPUT="output/{slug}.md"
if [[ ! -s "$OUTPUT" ]]; then
  echo "ERROR: conversion produced an empty file"
  exit 1
fi

PDF_PAGES=$(pdfinfo "input/{file}.pdf" 2>/dev/null | grep 'Pages:' | awk '{print $2}' || echo 0)
WORD_COUNT=$(wc -w < "$OUTPUT")
if [[ "$PDF_PAGES" -gt 0 ]]; then
  WORDS_PER_PAGE=$((WORD_COUNT / PDF_PAGES))
  if [[ "$WORDS_PER_PAGE" -lt 50 ]]; then
    echo "WARNING: only ${WORDS_PER_PAGE} words per page were extracted; the PDF may be scanned or partially unreadable."
    echo "Pages: ${PDF_PAGES}, words: ${WORD_COUNT}"
  fi
fi

H1_COUNT=$(grep -c '^# ' "$OUTPUT" || echo 0)
if [[ "$H1_COUNT" -eq 0 ]]; then
  echo "NOTE: no H1 headings were detected; the structure may need manual repair."
fi
```

---

## Notes

- Image-only PDFs require OCR such as `tesseract`; this skill does not perform OCR.
- If the output is tiny or nearly empty, record the issue in `memory.md` and skip publication.
- Keep the original PDF; do not delete it as part of conversion.
