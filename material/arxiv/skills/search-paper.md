# Skill: Search arXiv by keyword

## Purpose

Use the official arXiv Atom API to search papers by keyword and return a structured result set with `arxiv_id`, title, authors, abstract preview, and publication time.

---

## Prerequisites

- `curl`
- `python3` for parsing XML

Check availability:

```bash
curl --version && python3 --version
```

---

## Steps

### Step 1: build the search request

API endpoint: `http://export.arxiv.org/api/query`

| Parameter | Meaning | Example |
|---|---|---|
| `search_query` | Search expression with field prefixes | `ti:transformer+AND+abs:attention` |
| `start` | Result offset | `0` |
| `max_results` | Number of results to return | `10` |
| `sortBy` | Sort field | `submittedDate` |
| `sortOrder` | Sort direction | `descending` |

Supported field prefixes include `ti` (title), `abs` (abstract), `au` (author), `cat` (category), and `all`.

```bash
QUERY="all:${KEYWORD}"
QUERY_ENC=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "${QUERY}")

curl -sL "http://export.arxiv.org/api/query?search_query=${QUERY_ENC}&start=0&max_results=${MAX_RESULTS:-10}&sortBy=submittedDate&sortOrder=descending" \
  -o "/tmp/arxiv-search-result.xml"
```

### Step 2: parse the response

```bash
python3 - <<'PYEOF'
import xml.etree.ElementTree as ET

ns = {
    "atom": "http://www.w3.org/2005/Atom",
    "arxiv": "http://arxiv.org/schemas/atom",
}

root = ET.parse("/tmp/arxiv-search-result.xml").getroot()

for entry in root.findall("atom:entry", ns):
    arxiv_id = entry.find("atom:id", ns).text.split("/abs/")[-1]
    title = entry.find("atom:title", ns).text.strip().replace("\n", " ")
    published = entry.find("atom:published", ns).text
    authors = [a.find("atom:name", ns).text for a in entry.findall("atom:author", ns)]
    summary = entry.find("atom:summary", ns).text.strip().replace("\n", " ")
    print(f"{arxiv_id}\t{title}\t{published}\t{'; '.join(authors)}\t{summary[:160]}")
PYEOF
```

### Step 3: filter already processed papers

```bash
grep -oP 'arxiv_id: \K\S+' material/arxiv/memory.md 2>/dev/null || true
```

The caller should exclude IDs that already exist in `memory.md`.

---

## Outputs

- TSV rows on stdout, or a temporary file such as `/tmp/arxiv-papers.tsv`
- a result list suitable for `fetch-paper.md` or the arXiv source plugin

---

## Notes

- arXiv enforces rate limits; keep at least a few seconds between requests when issuing many searches.
- `max_results` may go up to 2000, but small batches are easier to review and safer to process incrementally.
- An empty result set should end cleanly without raising an error.
- Always URL-encode queries that contain spaces or special characters.
