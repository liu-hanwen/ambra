# Ambra

> English documentation: [README.md](README.md)
>
> 把论文、书、网页、周刊和本地文件，逐步沉淀成一个会持续进化的 Markdown 研究型知识库。

Ambra 是一个以仓库为载体、以 AI Agent 为执行者的研究产品。它不是只会吐一次性摘要的黑盒，而是把原始材料一步步转成可阅读的 brief、可复用的 knowledge、更高层的 wisdom，以及后续值得追的 idea，并把这些结果都保存在你自己的文件里。

如果你希望研究过程能长期积累、能复查、能回溯、能持续变强，Ambra 就是在做这件事。

---

## Ambra 能给你什么

- **不是堆材料，而是把材料读出来** —— 原始 PDF、网页、电子书会先变成结构清晰的 brief。
- **不是临时摘要，而是可复用认知资产** —— 重要概念会沉淀成可合并、可复用的 knowledge。
- **不是信息罗列，而是更高层的综合理解** —— Ambra 会把重复出现的模式提炼成 wisdom。
- **不是停在理解，而是继续往前推** —— 它会围绕你的研究方向生成 idea，并推荐可能值得扩展的相邻主题。
- **每次更新都看得见** —— 每轮完整处理都会写入 `changelog/`，让你知道新增了什么、改了什么、出现了什么新 insight。
- **语言和偏好都是你的** —— `vault-language.txt` 和 `user.md` 让整个 vault 更贴近你的工作方式。

---

## 适合谁

如果你符合下面这些情况，Ambra 会很适合你：

- 你长期读论文、书、文章、报告、周刊，不想让内容只停留在原文里
- 你希望 AI 帮你做研究整理，但又不想把结果锁死在某个黑盒系统里
- 你想要的是会持续增值的研究型 vault，而不是一次性的总结
- 你本来就习惯 Markdown / Obsidian 一类的知识管理方式

---

## Usage

**请把 `SKILL/ambra/SKILL.md` 当作使用 Ambra 的主入口。** 它暴露了这些标准 workflow：

| Workflow | 可以让 agent 帮你做什么 |
|---|---|
| `ambra:init` | 创建并初始化一个新的 vault |
| `ambra:user` | 创建、完善或审查 `user.md` |
| `ambra:localize` | 切换或整理 vault 的下游输出语言 |
| `ambra:add-source` | 注册或扩展一个数据源 |
| `ambra:search` | 在已有数据源里搜索并摄入内容 |
| `ambra:import` | 导入本地 PDF、EPUB 等文件 |
| `ambra:run` | 把整个 vault 更新到最新状态 |
| `ambra:dream` | 从全局角度整理、合并并深化整个 vault |

这些是 **workflow 名称，不是 shell 命令**。你可以直接点名，也可以自然语言触发，例如：

```text
请用 ambra:init 在 ~/vaults/investing 创建一个新的中文 vault。
请用 ambra:user 帮我把这个 vault 的长期偏好整理清楚。
请用 ambra:add-source 添加一个周刊数据源，并默认拉最近一篇跑通流程。
请用 ambra:import 把这些本地 EPUB 文件导入 Ambra。
请用 ambra:run 把整个 vault 更新完，并告诉我这次新增了什么 insight。
请用 ambra:dream 整理重复 knowledge，合并弱 wisdom，看看有没有新的方向可挖。
```

如果 workflow 涉及数据源过滤、下游强调重点或 idea 生成，Ambra 应读取 `user.md`；如果会写下游笔记，则应遵循 `vault-language.txt`。

---

## 一次完整 Ambra 运行会产出什么

| 阶段 | 你给它什么 | 它产出什么 |
|---|---|---|
| `material` | PDF、EPUB、网页、订阅源、本地文件 | 保持来源忠实的 Markdown 材料 |
| `brief` | 难快速吸收的原始材料 | 更清晰、更易读、但不丢关键信息的 brief |
| `knowledge` | 文档级理解 | 原子化、可复用的知识点 |
| `wisdom` | 一批相关 knowledge | 更高层的综合理解、框架、方法论 |
| `idea` | 新就绪的 knowledge + 你的研究方向 | 可行动的 idea 与相邻主题推荐 |
| `changelog` | 一次完整下游运行 | 一份告诉你“这次到底更新了什么”的更新简报 |

---

## 快速开始

1. 先确保本地环境基本可用：`python3`、`sqlite3`、`pandoc`、`pyyaml` 是最关键的依赖。
2. 在仓库根目录运行 `./scripts/init-db.sh`，生成本地 `queue.db`。
3. 在 `vault-language.txt` 里确定你希望的下游输出语言。
4. 创建或完善 `user.md`，告诉 Ambra 你的长期偏好。
5. 用 `ambra:add-source` 添加数据源，或者用 `ambra:import` 导入本地文件。
6. 运行 `ambra:run`，让内容经过 `brief -> knowledge -> wisdom / idea`。
7. 打开 `changelog/` 看这次更新了什么，再顺着链接进入具体笔记。

> `queue.db` 是本地运行时状态文件，默认不会提交到 Git。
>
> Git 维护默认是关闭的；如果你希望 Ambra 自动提交持久化改动，需要明确开启。

---

## Ambra 和一般“AI 摘要工具”有什么不同

- **它是 vault-first 的** —— 最终资产是你仓库里的 Markdown 文件，不是平台里的黑盒数据。
- **它是 agentic，但可检查的** —— prompt、workflow、约束、结果都在仓库里。
- **它不是只做 summary** —— Ambra 的重点是保留信息、沉淀 knowledge、提升 synthesis。
- **它会考虑语言和偏好** —— 下游语言、标签、输出风格和 idea 方向都能和你匹配。
- **它能持续演化** —— 新材料进来后，不只是多一篇摘要，而是会推动整个 vault 往前长。

---

## Ambra 是怎么工作的

```text
material -> brief -> knowledge -> wisdom
                             \-> idea（与 wisdom 并行）
```

| 层级 | 职责 |
|---|---|
| **material** | 获取或导入原始内容，并转成干净的 Markdown |
| **brief** | 用更清晰的结构和语言把原始内容“还原出来” |
| **knowledge** | 抽取可复用概念，并和已有内容去重整合 |
| **wisdom** | 将多个 knowledge 综合成更高层的理解 |
| **idea** | 面向用户研究方向生成可行动的新想法 |

更偏技术的调度规则在根 `AGENTS.md`，agent 的主要操作入口在 `SKILL/ambra/SKILL.md`。

---

## 关键运行约定

### `user.md`

`user.md` 是这个 vault 的长期偏好档案，可以影响数据源过滤、优先级、下游强调重点、idea 方向，甚至是否自动维护 git。

### `vault-language.txt`

`vault-language.txt` 用来定义 `brief/`、`knowledge/`、`wisdom/`、`idea/` 和 `tags.md` 的规范输出语言；`material/` 保持来源忠实，不强制翻译。

### `changelog/`

每次完整的下游处理后，Ambra 都应写一份可跳转的更新简报，尤其要点名哪些 wisdom / idea 发生了变化，以及这次最重要的新 insight 是什么。

### Pipeline Gate

Ambra 用 publish unit + versioned consumption 的门禁模型，确保下游只消费已经完整就绪的上游结果，也确保内容变更后可以安全重跑。

---

## 目录结构

```text
.
|- SKILL/ambra/            # 主操作技能入口
|- material/               # 忠于来源的 Markdown 材料与数据源插件
|- brief/                  # 更易读的内容重构
|- knowledge/              # 原子化、可复用的知识点
|- wisdom/                 # 更高层的综合理解
|- idea/                   # 用户研究方向与系统推荐主题
|- changelog/              # 每轮运行的更新简报
|- user.md                 # 用户长期偏好档案
|- vault-language.txt      # 下游规范输出语言
|- tags.md                 # 全局标签体系
|- tag-dataview.md         # 从 tag 视角看全局内容
|- scripts/                # 初始化和共享脚本
\- migrations/             # SQLite schema 与 migration
```

---

## 如何扩展 Ambra

- 在 `idea/` 下新建一个带 `AGENTS.md` 的子目录，就能新增研究方向。
- 在 `material/{source}/AGENTS.md` 中定义新的数据源插件。
- 把可复用脚本放在 `material/skills/scripts/` 下，供各层共享。
- 如果要看技术契约，请从 `SKILL/ambra/SKILL.md` 和根 `AGENTS.md` 开始读。
