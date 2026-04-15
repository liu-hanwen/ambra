#!/usr/bin/env python3
"""Scan Markdown files and repair missing reverse links in YAML front matter.

Bidirectional link pairs across the DIKW pipeline:
  material.brief    <-> brief.material
  brief.knowledge   <-> knowledge.briefs
  knowledge.wisdoms <-> wisdom.knowledge

Usage:
  python3 sync-bidirectional-links.py [--dry-run] [--root <project-root>]

Options:
  --dry-run    Report missing reverse links without modifying files.
  --root       Explicit project root. If omitted, infer it automatically.

Examples:
  python3 material/skills/scripts/sync-bidirectional-links.py --dry-run --root .
  python3 material/skills/scripts/sync-bidirectional-links.py --root .
"""

import argparse
import os
import re
import sys

import yaml


# ---------------------------------------------------------------------------
# Front matter helpers
# ---------------------------------------------------------------------------

def split_frontmatter(text):
    """Split Markdown text into (front_matter_str, body_str)."""
    if not text.startswith('---'):
        return None, text
    m = re.match(r'^---\r?\n(.*?\r?\n)---\r?\n', text, re.DOTALL)
    if not m:
        return None, text
    return m.group(1), text[m.end():]


def read_fm(path):
    """Read front matter and body. Return (fm_dict, body_str) or (None, None)."""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        fm_str, body = split_frontmatter(content)
        if fm_str is None:
            return {}, content
        fm = yaml.safe_load(fm_str) or {}
        return fm, body
    except Exception as e:  # noqa: BLE001 - command-line utility; report and continue
        print(f"WARNING: failed to read {path}: {e}", file=sys.stderr)
        return None, None


def write_fm(path, fm, body):
    """Write front matter and body back to disk."""
    new_fm_str = yaml.dump(fm, allow_unicode=True, default_flow_style=False, sort_keys=False)
    new_content = f'---\n{new_fm_str}---\n{body}'
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)


def ensure_link(fm, field, link_value):
    """Ensure fm[field] contains link_value. Return True if the mapping changed."""
    existing = fm.get(field)
    if existing is None or existing == []:
        fm[field] = [link_value]
        return True
    if not isinstance(existing, list):
        existing = [existing]
        fm[field] = existing
    if link_value not in existing:
        existing.append(link_value)
        return True
    return False


def wikilink(rel_path_no_ext):
    """Return the value in [[path]] form."""
    return f"[[{rel_path_no_ext}]]"


def strip_ext(path):
    return os.path.splitext(path)[0]


# ---------------------------------------------------------------------------
# File scanning helpers
# ---------------------------------------------------------------------------

SKIP_FILES = {'AGENTS.md', 'memory.md', 'tags.md'}


def collect_md_files(layer_dir):
    """Recursively collect content Markdown files under one layer directory."""
    result = []
    for root, dirs, files in os.walk(layer_dir):
        # Ignore hidden directories.
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for fname in files:
            if fname.endswith('.md') and fname not in SKIP_FILES:
                result.append(os.path.join(root, fname))
    return result


def extract_links(fm, field):
    """Extract [[...]] targets from fm[field] and return them without brackets."""
    raw = fm.get(field, [])
    if raw is None:
        return []
    if isinstance(raw, str):
        raw = [raw]
    links = []
    for item in raw:
        m = re.match(r'\[\[(.+?)\]\]', str(item))
        if m:
            links.append(m.group(1))
    return links


def rel_no_ext(path, root_dir):
    """Return the path relative to the project root, without its extension."""
    return strip_ext(os.path.relpath(path, root_dir))


# ---------------------------------------------------------------------------
# Main synchronization logic
# ---------------------------------------------------------------------------

LINK_PAIRS = [
    ('material', 'brief', 'brief', 'material'),
    ('brief', 'knowledge', 'knowledge', 'briefs'),
    ('knowledge', 'wisdoms', 'wisdom', 'knowledge'),
]


def sync_links(root_dir, dry_run=False):
    """Scan all layers and fill missing reverse links. Return a list of changes."""
    changes = []

    for src_layer, src_field, dst_layer, dst_field in LINK_PAIRS:
        src_dir = os.path.join(root_dir, src_layer)
        if not os.path.isdir(src_dir):
            continue

        for src_path in collect_md_files(src_dir):
            fm, _body = read_fm(src_path)
            if fm is None:
                continue

            for link_path in extract_links(fm, src_field):
                # link_path is relative to the project root and has no extension.
                dst_path = os.path.join(root_dir, link_path + '.md')
                if not os.path.exists(dst_path):
                    continue

                dst_fm, dst_body = read_fm(dst_path)
                if dst_fm is None:
                    continue

                # The reverse link should point back to the current source file.
                reverse_link = wikilink(rel_no_ext(src_path, root_dir))

                if ensure_link(dst_fm, dst_field, reverse_link):
                    changes.append({
                        'file': dst_path,
                        'field': dst_field,
                        'value': reverse_link,
                    })
                    if not dry_run:
                        write_fm(dst_path, dst_fm, dst_body)

    return changes


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Scan Markdown content and synchronize DIKW bidirectional links.'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Report missing reverse links without modifying files.',
    )
    parser.add_argument(
        '--root',
        default=None,
        help='Project root containing material/, brief/, knowledge/, and wisdom/.',
    )
    args = parser.parse_args()

    if args.root:
        root_dir = os.path.abspath(args.root)
    else:
        # The script lives in material/skills/scripts/, so the repo root is three levels up.
        script_dir = os.path.dirname(os.path.abspath(__file__))
        root_dir = os.path.abspath(os.path.join(script_dir, '../../../'))

    if not os.path.isdir(root_dir):
        print(f"ERROR: project root not found: {root_dir}", file=sys.stderr)
        sys.exit(1)

    print(f"Project root: {root_dir}")
    if args.dry_run:
        print("Mode: report only (no files will be modified)\n")
    else:
        print("Mode: apply missing reverse links\n")

    changes = sync_links(root_dir, dry_run=args.dry_run)

    if not changes:
        print("OK: all bidirectional links are already synchronized.")
    else:
        for change in changes:
            rel_path = os.path.relpath(change['file'], root_dir)
            action = "Would update" if args.dry_run else "Updated"
            print(f"  {action}: {rel_path} -> {change['field']} += {change['value']}")
        summary = "pending repairs" if args.dry_run else "link repairs"
        print(f"\nCompleted {len(changes)} {summary}.")
        if args.dry_run:
            print("Run again without --dry-run to apply the fixes.")


if __name__ == '__main__':
    main()
