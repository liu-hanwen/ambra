# Skill: Download an arXiv PDF and convert it to Markdown

## Purpose

Given an arXiv ID, download the paper PDF, convert it to Markdown, prepend front matter, and publish the result as a ready material unit under `material/arxiv/`.

---

## Prerequisites

- `curl`
- either `pandoc` or `pdftotext` from `poppler-utils`

Check availability:

```bash
curl --version && (pandoc --version || pdftotext -v)
```

---

## Steps

### Step 1: download the PDF

```bash
ARXIV_ID="{arxiv_id}"   # example: 2401.12345 or 2401.12345v2
PDF_URL="https://arxiv.org/pdf/${ARXIV_ID}"
PDF_PATH="/tmp/${ARXIV_ID}.pdf"

curl -sL --max-time 120 -A "Mozilla/5.0" \
  "${PDF_URL}" -o "${PDF_PATH}"

if ! file "${PDF_PATH}" | grep -q "PDF"; then
  echo "ERROR: download failed or the result is not a valid PDF"
  exit 1
fi

echo "Downloaded PDF size: $(du -sh "${PDF_PATH}")"
```

### Step 2: fetch metadata from the arXiv API

```bash
META_XML="/tmp/${ARXIV_ID}-meta.xml"
curl -sL "http://export.arxiv.org/api/query?id_list=${ARXIV_ID}" -o "${META_XML}"

python3 - <<'PYEOF'
import os
import xml.etree.ElementTree as ET

arxiv_id = os.environ["ARXIV_ID"]
meta_xml = f"/tmp/{arxiv_id}-meta.xml"
ns = {"atom": "http://www.w3.org/2005/Atom"}
root = ET.parse(meta_xml).getroot()
entry = root.find("atom:entry", ns)

title = entry.find("atom:title", ns).text.strip().replace("\n", " ")
authors = [a.find("atom:name", ns).text for a in entry.findall("atom:author", ns)]
published = entry.find("atom:published", ns).text
summary = entry.find("atom:summary", ns).text.strip().replace("\n", " ")

print(f"TITLE={title}")
print(f"AUTHORS={', '.join(authors)}")
print(f"PUBLISHED={published}")
print(f"SUMMARY_PREVIEW={summary[:200]}...")
PYEOF
```

### Step 3: convert PDF to Markdown

See the shared PDF skill at `material/skills/pdf-to-markdown.md`.

```bash
MD_PATH="material/arxiv/${ARXIV_ID}.md"

# Option A: direct conversion with pandoc
pandoc -f pdf -t markdown --wrap=none \
  -o "${MD_PATH}" "${PDF_PATH}"

# Option B: fallback through pdftotext
# pdftotext -layout "${PDF_PATH}" "/tmp/${ARXIV_ID}.txt"
# pandoc -f plain -t markdown --wrap=none -o "${MD_PATH}" "/tmp/${ARXIV_ID}.txt"
```

### Step 4: prepend front matter

```bash
TMP_PATH="$(mktemp)"
python3 - <<'PYEOF' > "${TMP_PATH}"
import datetime
import os
import xml.etree.ElementTree as ET
import yaml

arxiv_id = os.environ["ARXIV_ID"]
meta_xml = f"/tmp/{arxiv_id}-meta.xml"
ns = {"atom": "http://www.w3.org/2005/Atom"}
root = ET.parse(meta_xml).getroot()
entry = root.find("atom:entry", ns)

title = entry.find("atom:title", ns).text.strip().replace("\n", " ")
authors = [a.find("atom:name", ns).text for a in entry.findall("atom:author", ns)]

front_matter = {
    "source_url": f"https://arxiv.org/abs/{arxiv_id}",
    "fetched_at": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "format": "pdf",
    "arxiv_id": arxiv_id,
    "title": title,
    "authors": authors,
    "brief": "",
}

print("---")
print(yaml.dump(front_matter, allow_unicode=True, default_flow_style=False, sort_keys=False).rstrip())
print("---")
PYEOF

cat "${MD_PATH}" >> "${TMP_PATH}"
mv "${TMP_PATH}" "${MD_PATH}"
```

### Step 5: register the paper and publish a ready unit

```bash
./scripts/sqlite.sh "INSERT OR IGNORE INTO materials (path) VALUES ('material/arxiv/${ARXIV_ID}.md');"

./scripts/sqlite.sh "
  INSERT OR IGNORE INTO pipeline_units
    (unit_id, layer, unit_type, source_kind, source_key, root_path, required_count)
    VALUES ('material:paper:arxiv/${ARXIV_ID}', 'material', 'single', 'paper', 'arxiv/${ARXIV_ID}', 'material/arxiv/${ARXIV_ID}.md', 1);

  INSERT OR IGNORE INTO pipeline_unit_members
    (unit_id, member_path, member_role, member_type)
    VALUES ('material:paper:arxiv/${ARXIV_ID}', 'material/arxiv/${ARXIV_ID}.md', 'required', 'file');

  UPDATE pipeline_unit_members
    SET member_status='done', member_version=member_version+1, updated_at=datetime('now')
    WHERE unit_id='material:paper:arxiv/${ARXIV_ID}' AND member_path='material/arxiv/${ARXIV_ID}.md';

  UPDATE pipeline_units SET
    done_count = 1,
    blocked_count = 0,
    status = 'ready',
    ready_version = ready_version + 1,
    ready_at = datetime('now'),
    updated_at = datetime('now')
  WHERE unit_id='material:paper:arxiv/${ARXIV_ID}';
"
```

---

## Outputs

- Markdown file: `material/arxiv/{arxiv_id}.md`
- Ready material publish unit: `material:paper:arxiv/{arxiv_id}`

---

## Notes

- arXiv may redirect a bare ID to the latest version; `curl -L` already handles that.
- If the PDF is image-only and the extracted text is too small to be useful, record the issue in `memory.md` and skip it until OCR is available.
- Clean up temporary files in `/tmp/` after the run: `rm -f /tmp/${ARXIV_ID}.*`
- If the paper already exists, the workflow stays idempotent at the database level even if you choose to refresh the Markdown file.
