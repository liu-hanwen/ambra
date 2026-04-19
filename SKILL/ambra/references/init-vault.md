# Workflow: `ambra:init`

Use this when the user wants a fresh Ambra vault at a target path.

## Steps

1. Read `preflight.md` and confirm the environment is viable.
2. Confirm the target directory.
3. Determine the default downstream output language:
   - if the user explicitly names a language, use it
   - otherwise infer it from the user's own instruction language
   - fall back to English only if the user's language is unclear or mixed
4. Determine the git-maintenance mode:
   - default: disabled
   - enable it only if the user explicitly wants Ambra-managed git commits
5. Clone the canonical repository:
   ```bash
   git clone git@github.com:liu-hanwen/ambra.git <target-dir>
   ```
6. Detach the new vault from Ambra's upstream history:
   ```bash
   cd <target-dir>
   rm -rf .git
   ```
7. If git maintenance is enabled, or if the user explicitly asks for an immediate commit during initialization:
   - if a parent directory already belongs to a git repository, reuse that parent repository and do not run `git init`
   - otherwise run `git init` inside the target directory
8. If git maintenance is disabled and the user did not explicitly ask for an immediate commit, leave the vault without its own `.git` directory after removing Ambra's upstream history.
9. Write the chosen language code to `vault-language.txt`.
10. Create `user.md` as the durable user profile for this vault:
   - if the user already stated stable preferences, write them down now
   - otherwise scaffold the file with a lean starter structure and guide the user to refine it through `ambra:user`
   - include the git-maintenance preference, which defaults to disabled
   - keep the file path fixed as `user.md`, even if the content itself is in the user's language
11. If the target vault language is not English, localize downstream contracts and prompts accordingly:
   - `material` remains source-faithful
   - `brief`, `knowledge`, `wisdom`, and `idea` should localize titles, section headings, body content, and tags
   - downstream filename changes require a coordinated contract rewrite, not isolated edits
12. Run:
   ```bash
   ./scripts/init-db.sh
   ```
13. Verify:
    - root layout is intact
    - `README.md`, `AGENTS.md`, `tags.md`, and downstream layer specs reflect the intended language policy
    - `vault-language.txt` matches the intended default language
    - `user.md` exists and either reflects the stated durable defaults already or provides a starter structure for later refinement through `ambra:user`
    - git maintenance mode matches the user's choice
    - if git maintenance is enabled and a parent repo exists, the vault reuses that parent repo instead of creating a nested repo
    - if git maintenance is disabled and no immediate commit was requested, Ambra did not create a fresh git repo for the new vault
    - `.gitignore` protects generated database files
    - if a git repository is active for this vault, `git status --short` does not show `queue.db` as a tracked change
14. If git maintenance is enabled or the user explicitly asks for a commit, commit the durable vault setup changes with an `ambra` marker in the subject.

## Checklist

- [ ] preflight passed
- [ ] target directory confirmed
- [ ] default vault language explicitly chosen or inferred from the user's language
- [ ] git-maintenance mode chosen and defaulted to disabled unless the user opted in
- [ ] repository cloned from `git@github.com:liu-hanwen/ambra.git`
- [ ] upstream git history removed
- [ ] parent git reuse or standalone `git init` was handled correctly when git maintenance was enabled or an immediate commit was explicitly requested
- [ ] `vault-language.txt` written correctly
- [ ] `user.md` created or updated as the initial profile or starter scaffold
- [ ] localization policy applied if needed
- [ ] downstream titles, headings, and tags aligned with the chosen language
- [ ] database initialized successfully
- [ ] generated DB files remain untracked
- [ ] `git status` verification was applied only when a git repository was active
- [ ] durable setup changes committed only when git maintenance was enabled or explicitly requested
