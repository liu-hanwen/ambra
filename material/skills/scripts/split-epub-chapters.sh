#!/usr/bin/env bash
# split-epub-chapters.sh
# Purpose: split one combined Markdown file, typically produced from an EPUB,
# into chapter files using H1 headings as boundaries.
#
# Usage:
#   bash split-epub-chapters.sh <input.md> <output_dir/>
#
# Output:
#   output_dir/c01-chapter-name.md, c02-chapter-name.md, ...

set -euo pipefail

INPUT="$1"
OUTPUT_DIR="$2"

mkdir -p "$OUTPUT_DIR"

chapter=0
outfile=""
buffer=""

slugify() {
    # Lowercase ASCII letters and collapse any non [a-z0-9] run into hyphens.
    # This intentionally normalizes non-ASCII characters instead of attempting
    # locale-sensitive transliteration inside sed.
    echo "$1" | tr '[:upper:]' '[:lower:]' | \
        sed 's/[^a-z0-9]/-/g' | \
        sed 's/-\+/-/g' | \
        sed 's/^-//;s/-$//'
}

while IFS= read -r line; do
    if [[ "$line" =~ ^#[[:space:]] ]]; then
        # Flush the previous chapter before starting a new one.
        if [[ -n "$outfile" && -n "$buffer" ]]; then
            printf '%s\n' "$buffer" > "$outfile"
        fi

        chapter=$((chapter + 1))
        title="${line#\# }"
        slug=$(slugify "$title")
        prefix=$(printf "c%02d" "$chapter")
        outfile="$OUTPUT_DIR/${prefix}-${slug}.md"
        buffer="$line"
    else
        if [[ -n "$outfile" ]]; then
            buffer="$buffer"$'\n'"$line"
        fi
    fi
done < "$INPUT"

# Flush the final buffered chapter.
if [[ -n "$outfile" && -n "$buffer" ]]; then
    printf '%s\n' "$buffer" > "$outfile"
fi

echo "Split complete: ${chapter} chapters written to ${OUTPUT_DIR}"
