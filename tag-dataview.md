# Tag Dataview

This dashboard assumes the Obsidian Dataview plugin is enabled.

It is meant to show how semantic tag branches propagate through `brief/`, `knowledge/`, `wisdom/`, and `idea/`.

## Coverage by branch prefix

```dataviewjs
const layers = ["brief", "knowledge", "wisdom", "idea"];
const pages = dv.pages()
  .where(p => layers.some(layer => String(p.file.path).startsWith(layer + "/")) && p.tags && p.tags.length);

const branchPrefixes = tag => {
  const parts = String(tag).split("/").filter(Boolean);
  const prefixes = [];
  for (let i = 0; i < parts.length; i++) {
    prefixes.push(parts.slice(0, i + 1).join("/"));
  }
  return prefixes;
};

const byBranch = new Map();

for (const page of pages) {
  const layer = page.file.path.split("/")[0];
  for (const tag of page.tags) {
    for (const branch of branchPrefixes(tag)) {
      if (!byBranch.has(branch)) {
        byBranch.set(branch, {
          brief: new Map(),
          knowledge: new Map(),
          wisdom: new Map(),
          idea: new Map(),
          notes: new Map(),
        });
      }

      const row = byBranch.get(branch);
      row[layer].set(page.file.path, page.file.link);
      row.notes.set(page.file.path, page.file.link);
    }
  }
}

const rows = Array.from(byBranch.entries())
  .map(([branch, row]) => {
    const brief = row.brief.size;
    const knowledge = row.knowledge.size;
    const wisdom = row.wisdom.size;
    const idea = row.idea.size;
    const total = row.notes.size;
    return [
      branch,
      brief,
      knowledge,
      wisdom,
      idea,
      total,
      Array.from(row.notes.values()),
    ];
  })
  .sort((a, b) => b[5] - a[5] || a[0].localeCompare(b[0]));

dv.table(
  ["Branch", "Brief", "Knowledge", "Wisdom", "Idea", "Total", "Notes"],
  rows
);
```

## Leaf tags

```dataviewjs
const layers = ["brief", "knowledge", "wisdom", "idea"];
const pages = dv.pages()
  .where(p => layers.some(layer => String(p.file.path).startsWith(layer + "/")) && p.tags && p.tags.length);

const leaves = new Map();

for (const page of pages) {
  const layer = page.file.path.split("/")[0];
  for (const tag of page.tags) {
    const leaf = String(tag);
    if (!leaves.has(leaf)) {
      leaves.set(leaf, {
        brief: new Map(),
        knowledge: new Map(),
        wisdom: new Map(),
        idea: new Map(),
      });
    }

    leaves.get(leaf)[layer].set(page.file.path, page.file.link);
  }
}

const rows = Array.from(leaves.entries())
  .map(([leaf, row]) => [
    leaf,
    row.brief.size,
    row.knowledge.size,
    row.wisdom.size,
    row.idea.size,
    row.brief.size + row.knowledge.size + row.wisdom.size + row.idea.size,
  ])
  .sort((a, b) => b[5] - a[5] || a[0].localeCompare(b[0]));

dv.table(["Leaf Tag", "Brief", "Knowledge", "Wisdom", "Idea", "Total"], rows);
```
