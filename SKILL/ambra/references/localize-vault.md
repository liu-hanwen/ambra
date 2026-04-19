# Workflow: `ambra:localize`

Use this when the user already has a vault and wants to change its operating language.

## Steps

1. Confirm the target output language. If not explicitly stated, infer it from the user's instruction language.
2. Read `user.md` if it exists and decide whether language-sensitive preferences inside it should also be refreshed.
3. Decide whether the user wants:
   - the default behavior: localize downstream filenames as well
   - an exception: preserve existing filenames while only localizing displayed content
4. Update `vault-language.txt` first so the vault has one canonical downstream language.
5. Localize prompt wording as needed.
6. If `user.md` contains durable language, naming, or tone preferences that should follow the new vault language, update them too.
7. If downstream filenames should be localized:
   - update `brief`, `knowledge`, `wisdom`, and `idea` path/naming rules together
   - update README examples, wikilink examples, and tag taxonomy examples that depend on those paths
8. If the user explicitly wants to preserve old filenames:
   - keep existing downstream paths unchanged
   - still localize displayed titles, section headings, body content, and tags
9. Never relabel `material` paths just to satisfy localization.
10. If git maintenance is enabled or the user explicitly asks for a commit, make sure a git repository is active for the vault by reusing a parent repo or initializing a standalone repository if needed, then commit durable prompt/configuration changes with an `ambra` marker in the subject.

## Checklist

- [ ] target language explicitly chosen or inferred
- [ ] `user.md` was consulted if present
- [ ] `vault-language.txt` updated
- [ ] `user.md` was updated when its durable language-related preferences needed to change
- [ ] downstream filename localization handled or intentionally preserved
- [ ] `material` path contract preserved
- [ ] downstream note filenames, titles, headings, body content, and tags updated consistently with the chosen localization mode
- [ ] documentation/examples updated where needed
- [ ] durable changes committed only when git maintenance was enabled or explicitly requested
