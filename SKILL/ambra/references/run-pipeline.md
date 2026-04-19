# Workflow: `ambra:run`

Use this when the user wants the vault brought fully up to date.

## Run order

Before executing the downstream stages, read `vault-language.txt`, `AGENTS.md`, and the relevant layer contracts. Read `user.md` too when it exists so the run keeps stable user preferences consistent across filtering, synthesis, idea generation, and git policy.

1. initialize the database
2. finish pending material ingestion work
3. confirm the downstream language and tag taxonomy still match `vault-language.txt`
4. apply durable preferences from `user.md` where the current run does not specify otherwise
5. process ready material units through brief, using multipart briefs whenever one material item contains multiple clearly independent subcontents
6. process ready brief units through knowledge
7. process ready knowledge units through wisdom and idea, including the reserved recommendation space under `idea/recommend/` when the signals justify it
8. run bidirectional-link synchronization
9. update `changelog/` with a linked brief of what changed
10. if git maintenance is enabled or the user explicitly asks for a commit, make sure a git repository is active for the vault by reusing a parent repo or initializing a standalone repository if needed, then commit durable results with an `ambra` marker in the subject; otherwise leave the changes uncommitted and report them clearly

## Guardrails

- if the host agent supports sub-agents, use them only for layer-bounded or file-disjoint work; keep orchestration, gate reconciliation, and final completion checks in the main agent
- process by ready units, not raw table scans
- keep `pipeline_consumptions` accurate
- stop and surface blocked members rather than silently skipping them
- do not let tags drift into mixed-language branches inside one vault
- do not claim completion while ready units remain unconsumed unless the user explicitly scoped the run

## Persistence rule

Commit durable artifacts such as:

- briefs
- knowledge files
- wisdom files
- idea files
- tags
- prompts
- source-plugin memory that is intentionally durable

Do not commit generated database files. `queue.db` remains local runtime state. If git maintenance is disabled and the user did not explicitly ask for a commit, skip the automatic commit step entirely.

## Checklist

- [ ] preflight passed
- [ ] `vault-language.txt` consulted
- [ ] `user.md` was consulted if present
- [ ] root and downstream layer contracts were consulted
- [ ] database initialized
- [ ] pending material ingestion handled
- [ ] sub-agent delegation, if any, stayed within clear layer or file boundaries
- [ ] tag taxonomy still aligned with the vault language
- [ ] ready material units processed through brief
- [ ] multipart brief handling applied where needed
- [ ] ready brief units processed through knowledge
- [ ] ready knowledge units processed through wisdom, user directions, and `idea/recommend/` where justified
- [ ] `changelog/` updated with a linked summary
- [ ] bidirectional links checked
- [ ] durable results committed only when git maintenance was enabled or explicitly requested
