#!/usr/bin/env python3
"""Update YAML front matter in a Markdown file.

Usage:
  python3 update-frontmatter.py <file-path> set <field> <value>
      Set a field to the given value, replacing any existing value.

  python3 update-frontmatter.py <file-path> append <field> <value>
      Append one value to a list field. If the field does not exist, create it.
      If the value already exists, leave the file unchanged.

Examples:
  python3 update-frontmatter.py brief/source/item.md set material "[[material/source/item]]"
  python3 update-frontmatter.py brief/source/item.md append knowledge "[[knowledge/concept-a]]"
  python3 update-frontmatter.py knowledge/concept.md append briefs "[[brief/source/item]]"
"""

import re
import sys

import yaml


def split_frontmatter(text):
    """Split Markdown text into (front_matter_str, body_str).

    If no front matter exists, return (None, original_text).
    """
    if not text.startswith('---'):
        return None, text
    m = re.match(r'^---\r?\n(.*?\r?\n)---\r?\n', text, re.DOTALL)
    if not m:
        return None, text
    return m.group(1), text[m.end():]


def update_frontmatter(path, operation, field, value):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    fm_str, body = split_frontmatter(content)
    if fm_str is None:
        # No front matter yet; create a new mapping.
        fm = {}
        body = content
    else:
        fm = yaml.safe_load(fm_str) or {}

    if operation == 'set':
        fm[field] = value

    elif operation == 'append':
        existing = fm.get(field)
        if existing is None or existing == []:
            fm[field] = [value]
        elif isinstance(existing, list):
            if value not in existing:
                existing.append(value)
        else:
            # Convert a scalar into a list before appending.
            if existing != value:
                fm[field] = [existing, value]

    else:
        print(f"ERROR: unknown operation '{operation}'. Supported values: set, append", file=sys.stderr)
        sys.exit(1)

    # Keep non-ASCII characters intact because repository content may be multilingual.
    new_fm_str = yaml.dump(fm, allow_unicode=True, default_flow_style=False, sort_keys=False)
    new_content = f'---\n{new_fm_str}---\n{body}'

    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print(f"Updated {path}: {operation} {field} = {value}")


def main():
    if len(sys.argv) != 5:
        print(__doc__)
        sys.exit(1)

    path = sys.argv[1]
    operation = sys.argv[2]
    field = sys.argv[3]
    value = sys.argv[4]

    update_frontmatter(path, operation, field, value)


if __name__ == '__main__':
    main()
