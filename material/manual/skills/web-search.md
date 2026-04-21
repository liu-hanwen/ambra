# Skill: Search the web by keyword and return result URLs

## Purpose

Run a general-purpose web keyword search and return a ranked list of result URLs suitable for follow-on fetching with `material/skills/web-fetch.md`.

---

## Prerequisites

- `curl`
- `python3`

Check availability:

```bash
curl --version && python3 --version
```

---

## Strategy

Use the DuckDuckGo HTML search endpoint (no API key required). Fall back to constructing a search URL for other engines if DuckDuckGo is unavailable.

---

## Steps

### Step 1: fetch the search results page

```bash
KEYWORD="{keyword}"
KEYWORD_ENC=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "${KEYWORD}")

curl -sL --max-time 30 \
  -A "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" \
  -H "Accept-Language: en-US,en;q=0.9" \
  "https://html.duckduckgo.com/html/?q=${KEYWORD_ENC}" \
  -o "/tmp/ddg-results.html"
```

### Step 2: extract result URLs

```bash
python3 - <<'PYEOF'
import re

with open("/tmp/ddg-results.html", "r", encoding="utf-8", errors="replace") as f:
    html = f.read()

# DuckDuckGo wraps result links in uddg= query parameter
urls = re.findall(r'uddg=(https?[^&"]+)', html)

seen = set()
count = 0
for u in urls:
    import urllib.parse
    decoded = urllib.parse.unquote(u)
    if decoded not in seen:
        seen.add(decoded)
        print(decoded)
        count += 1
        if count >= int(__import__("os").environ.get("MAX_RESULTS", "5")):
            break
PYEOF
```

### Step 3: filter already-processed URLs

Before passing URLs to the fetch step, check `material/manual/memory.md` to skip URLs whose slugs are already registered. Match against the full entry format used in that file:

```bash
# Extract slugs already listed under "## Processed files" in memory.md
grep -oP '^- \K[^\s]+\.md' material/manual/memory.md 2>/dev/null || true
```

Compare each candidate result URL's derived slug against this list. Skip any URL whose slug is already present.

---

## Outputs

- One URL per line on stdout, suitable for piping into a fetch loop.
- Save to `/tmp/manual-search-results.txt` when processing multiple keywords sequentially.

```bash
MAX_RESULTS=5 python3 ... > /tmp/manual-search-results.txt
```

---

## Notes

- **Rate limiting:** add a two-second delay between searches when processing multiple keywords.
- **Empty results:** if fewer than `MAX_RESULTS` URLs are found, emit what is available without error. If zero results, print nothing and let the caller handle the empty case.
- **Anti-bot blocks:** if DuckDuckGo returns a CAPTCHA or 0 results, record a warning in `material/manual/memory.md` and skip the keyword.
- **Result quality:** prefer results from established domains; the caller (manual AGENTS.md) decides whether to use all results or filter further.
- Temporary HTML files belong in `/tmp/`; do not track them in the repository.
