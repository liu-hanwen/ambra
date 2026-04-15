# Workflow: `ambra:init`

Use this when the user wants a fresh Ambra vault at a target path.

## Steps

1. Read `preflight.md` and confirm the environment is viable.
2. Confirm the target directory.
3. Determine the default downstream output language:
   - if the user explicitly names a language, use it
   - otherwise infer it from the user's own instruction language
   - fall back to English only if the user's language is unclear or mixed
4. Clone the canonical repository:
   ```bash
   git clone git@github.com:liu-hanwen/ambra.git <target-dir>
   ```
5. Detach the new vault from Ambra's upstream history:
   ```bash
   cd <target-dir>
   rm -rf .git
   git init
   ```
6. Write the chosen language code to `vault-language.txt`.
7. Create `user.md` as the durable user profile for this vault:
   - if the user already stated stable preferences, write them down now
   - otherwise scaffold the file with a lean starter structure and guide the user to refine it through `ambra:user`
   - keep the file path fixed as `user.md`, even if the content itself is in the user's language
8. If the target vault language is not English, localize downstream contracts and prompts accordingly:
   - `material` remains source-faithful
   - `brief`, `knowledge`, `wisdom`, and `idea` should localize titles, section headings, body content, and tags
   - downstream filename changes require a coordinated contract rewrite, not isolated edits
9. Run:
   ```bash
   ./scripts/init-db.sh
   ```
10. Verify:
   - root layout is intact
   - `README.md`, `AGENTS.md`, `tags.md`, and downstream layer specs reflect the intended language policy
   - `vault-language.txt` matches the intended default language
   - `user.md` exists and either reflects the stated durable defaults already or provides a starter structure for later refinement through `ambra:user`
   - `.gitignore` protects generated database files
   - `git status --short` does not show `queue.db` as a tracked change
11. Commit the durable vault setup changes.

## Checklist

- [ ] preflight passed
- [ ] target directory confirmed
- [ ] default vault language explicitly chosen or inferred from the user's language
- [ ] repository cloned from `git@github.com:liu-hanwen/ambra.git`
- [ ] upstream git history removed
- [ ] fresh `git init` completed
- [ ] `vault-language.txt` written correctly
- [ ] `user.md` created or updated as the initial profile or starter scaffold
- [ ] localization policy applied if needed
- [ ] downstream titles, headings, and tags aligned with the chosen language
- [ ] database initialized successfully
- [ ] generated DB files remain untracked
- [ ] durable setup changes committed to git
