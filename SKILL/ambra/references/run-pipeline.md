# Workflow: `ambra:run`

Use this when the user wants the vault brought fully up to date.

## Run order

Before executing the downstream stages, read `vault-language.txt`, `AGENTS.md`, and the relevant layer contracts. Read `user.md` too when it exists so the run keeps stable user preferences consistent across filtering, synthesis, and idea generation.

1. initialize the database
2. finish pending material ingestion work
3. confirm the downstream language and tag taxonomy still match `vault-language.txt`
4. apply durable preferences from `user.md` where the current run does not specify otherwise
5. process ready material units through brief, using multipart briefs whenever one material item contains multiple clearly independent subcontents
6. process ready brief units through knowledge
7. process ready knowledge units through wisdom and idea
8. run bidirectional-link synchronization
9. commit durable results

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

Do not commit generated database files. `queue.db` remains local runtime state.

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
- [ ] ready knowledge units processed through wisdom and idea
- [ ] bidirectional links checked
- [ ] durable results committed to git
