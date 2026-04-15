# Skill: Fetch web content from a URL and convert it to Markdown

## Purpose

Fetch the main article body from a URL, strip obvious noise, and convert the result to Markdown.

---

## Prerequisites

- `curl` or `wget`
- `pandoc`
- optional: `python3` and `readability-lxml` for higher-quality content extraction

Check availability:

```bash
curl --version || wget --version
pandoc --version
python3 -c "import readability; print('readability ok')"  # optional
```

---

## Steps

### Option A: use readability (recommended)

```bash
curl -sL --max-time 30 -A "Mozilla/5.0" "{url}" -o "/tmp/{slug}.html"

python3 -c "
import sys
from readability import Document
with open(sys.argv[1], 'r', encoding='utf-8', errors='replace') as f:
    html = f.read()
doc = Document(html)
print(doc.summary())
" "/tmp/{slug}.html" > "/tmp/{slug}-clean.html"

pandoc -f html -t markdown --wrap=none \
  -o "material/{source}/{slug}.md" \
  "/tmp/{slug}-clean.html"
```

### Option B: direct `curl` plus `pandoc`

```bash
curl -sL --max-time 30 -A "Mozilla/5.0" "{url}" | \
  pandoc -f html -t markdown --wrap=none \
  -o "material/{source}/{slug}.md"
```

### Validation

```bash
wc -l "material/{source}/{slug}.md"
head -30 "material/{source}/{slug}.md"
```

---

## Outputs

- Markdown file: `material/{source}/{slug}.md`
- front matter is added later by the material agent, with `source_url` pointing to the fetched URL

---

## Notes

- **Anti-bot limits:** if the server returns 403 or 429, retry later or rotate the user agent. Stop after three attempts.
- **JavaScript-heavy pages:** if the extracted body is empty, escalate to a headless browser workflow and record the issue in `memory.md`.
- **Paywalled content:** record and skip it.
- **Rate limiting:** add a one- to three-second delay when fetching many URLs from the same domain.
- Temporary HTML files belong in `/tmp/`; do not track them in the repository.
