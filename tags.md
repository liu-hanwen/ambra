# Tag Dictionary

`tags.md` is the canonical taxonomy for downstream layers.

The goal is not to mint many clever tags. The goal is to keep tags reusable, hierarchical, and stable enough that `knowledge/`, `wisdom/`, `idea/`, and root-level Dataview dashboards can all rely on them.

## Language contract

- Tags must use the same working language as `vault-language.txt`.
- One vault should not keep parallel bilingual branches for the same concept.
- When localizing a vault, migrate old tags coherently instead of appending translated duplicates beside them.

## What tags are for

Use tags for **semantic retrieval**, not for operational bookkeeping.

- Good uses: domain, topic, method, application, evidence shape
- Do **not** use tags for: layer name, workflow status, language, temporary processing state, or whether a note is draft/final
- Layer information already exists in paths such as `brief/`, `knowledge/`, `wisdom/`, and `idea/`

## Hierarchy model

Prefer **2 to 4 levels**. Each level should narrow the meaning without switching semantic axis midway.

Recommended top-level families:

- `domain/...` - subject area or knowledge territory
- `topic/...` - concrete concept, object, mechanism, or theme
- `method/...` - method, framework, tool, or analytical lens
- `application/...` - use case, market, scenario, or deployment context
- `evidence/...` - evidence type, benchmark shape, or empirical pattern when this distinction matters

These family names should also follow `vault-language.txt`.

## Branch design rules

1. Reuse an existing branch before creating a new one.
2. Keep sibling branches semantically parallel.
3. Use concise noun phrases, not sentences.
4. Prefer one semantic axis per level:
   - good: `method/time-series/momentum`
   - bad: `quant-investing/mean-reversion/backtest-improvement`
5. Usually assign:
   - one **primary** tag from `domain/...` or `topic/...`
   - zero to two **supporting** tags from `method/...`, `application/...`, or `evidence/...`
6. Avoid over-tagging. Most notes should stay within **1 to 4** tags.
7. For Latin-script vaults, use lowercase kebab-case segments.
8. For CJK vaults, use concise natural phrases and avoid stray English siblings unless the term has no good native form.

## Ownership

- `knowledge/` is the primary layer that extends or restructures the taxonomy.
- `wisdom/` should mostly reuse dominant existing branches and only add a new higher-order branch when the synthesis truly introduces a stable new theme.
- `idea/` should usually inherit existing semantic branches instead of inventing a fresh taxonomy.
- `brief/` may leave `tags` empty unless a source-specific contract explicitly requires otherwise.

## Maintenance workflow

When a new concept appears:

1. look for an existing branch with the same meaning
2. if none exists, add the narrowest valid child under an existing family
3. if the old structure was wrong, migrate the whole branch coherently instead of leaving near-duplicates behind
4. keep `tag-dataview.md` readable by avoiding unnecessary one-off leaves

## Examples

English-style vault:

- domain/quant-investing
- topic/technical-analysis/trend-indicators
- method/time-series/momentum
- application/a-share-equities/intraday-trading
- evidence/backtest/high-turnover

Chinese-style vault:

- 领域/量化投资
- 主题/技术分析/趋势指标
- 方法/时间序列/动量
- 场景/A股/日内交易
- 证据/回测/高换手
