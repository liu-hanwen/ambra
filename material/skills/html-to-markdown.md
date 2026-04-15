# Skill: HTML to Markdown

## Purpose

Convert a local HTML file into Markdown while preserving the main article structure and removing common page chrome such as navigation, ads, or scripts.

---

## Prerequisites

- `pandoc` >= 2.x
- optional: `python3` and `beautifulsoup4` for HTML cleanup

Check availability:

```bash
pandoc --version
python3 -c "import bs4; print(bs4.__version__)"  # optional
```

---

## Steps

### Step 1 (optional): clean noisy HTML

If the HTML came from a scraped web page, remove tags such as `<nav>`, `<header>`, `<footer>`, `<aside>`, `<script>`, and `<style>` first:

```bash
python3 -c "
import sys
from bs4 import BeautifulSoup

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    soup = BeautifulSoup(f, 'html.parser')

for tag in soup(['nav', 'header', 'footer', 'aside', 'script', 'style', 'iframe']):
    tag.decompose()

main = soup.find('article') or soup.find('main') or soup.body
print(str(main))
" "input/{file}.html" > "/tmp/{slug}-clean.html"
```

### Step 2: convert to Markdown

```bash
pandoc -f html -t markdown \
  --wrap=none \
  -o "output/{slug}.md" \
  "/tmp/{slug}-clean.html"
```

If no cleanup is needed:

```bash
pandoc -f html -t markdown \
  --wrap=none \
  -o "output/{slug}.md" \
  "input/{file}.html"
```

### Step 3: inspect the result

```bash
wc -l "output/{slug}.md"
head -20 "output/{slug}.md"
```

---

## Outputs

- Markdown file: `material/{source}/{slug}.md`
- front matter is added by the material agent

---

## Notes

- If the page depends heavily on JavaScript rendering, static HTML may be too incomplete; switch to the web-fetch skill or a browser-based fetcher.
- Relative image paths may break after conversion. Download media locally or leave them as external links if necessary.
- Verify that the opening paragraphs contain real content rather than leftover navigation text.
