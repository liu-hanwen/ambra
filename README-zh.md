# Ambra

> English documentation: [README.md](README.md)

Ambra 是一个基于 DIKW（数据 -> 信息 -> 知识 -> 智慧）模型的个人知识管理流水线系统，借助 AI Agent 自动化完成从原始材料到可落地智慧的全链路处理。

---

## Usage

**请将 `SKILL/ambra/SKILL.md` 作为使用 Ambra 的主入口。** 它暴露了这些标准 workflow 标签：

| Workflow | 适用场景 |
|---|---|
| `ambra:init` | 创建并初始化一个新的 vault |
| `ambra:user` | 创建、完善或审查 `user.md` |
| `ambra:localize` | 本地化一个已有 vault |
| `ambra:add-source` | 注册或扩展一个 material 数据源 |
| `ambra:search` | 通过已有数据源搜索并摄入内容 |
| `ambra:import` | 导入本地文件并摄入 |
| `ambra:run` | 触发一次完整的 DIKW 流程 |
| `ambra:dream` | 从全局角度整理并深化整个 vault |

这些是 **workflow 名称，不是 shell 命令**。用户既可以直接点名，也可以自然语言触发，例如：

```text
请用 ambra:init 在 ~/vaults/investing 创建一个新的中文 vault。
请用 ambra:user 帮我完善用户画像，重点关注量化研究和双语阅读。
请用 ambra:add-source 添加一个周刊数据源，并默认拉取最近一篇做 smoke test。
请用 ambra:search 搜索三篇和时间序列动量相关的近期内容并摄入 Ambra。
请用 ambra:import 把这些本地 EPUB 文件导入 Ambra。
请用 ambra:run 把整个 vault 更新到最新状态。
请用 ambra:dream 整理重复 knowledge，并产出更强的 wisdom。
```

如果 workflow 涉及数据源过滤、下游输出取舍或 idea 生成，Ambra 还应读取 `user.md`；如果 workflow 会写入下游笔记，则应遵循 `vault-language.txt`。

---

## 系统架构

```text
material -> brief -> knowledge -> wisdom
                             \-> idea（与 wisdom 并行）
```

| 层级 | 职责 |
|---|---|
| **material** | 从外部获取内容（论文、电子书、网页等），转换为 Markdown |
| **brief** | 对每篇材料生成精读总结；如果一份 material 实际包含多个彼此独立的子内容，则拆成分 part 的 brief |
| **knowledge** | 从总结中提取原子知识点，去重整合 |
| **wisdom** | 聚类相关知识点，生成综合性认知文章 |
| **idea** | 结合用户研究方向，发散生成可落地的 IDEA |

---

## 目录结构

```text
.
|- AGENTS.md              # 根级调度规范（全局约束 + 流水线协调）
|- user.md                # 用户长期偏好档案，用于数据源过滤和下游输出偏好
|- SKILL/                 # 用于操作或扩展 Ambra 的技能入口
|- brief/                 # 精读总结
|  \- AGENTS.md
|- idea/                  # 灵感 IDEA（按研究方向子目录组织）
|  \- AGENTS.md
|- knowledge/             # 原子知识点（扁平结构）
|  \- AGENTS.md
|- material/              # 原始材料（Markdown 格式）
|  |- AGENTS.md
|  \- skills/            # 转换工具说明 + 可复用脚本
|     \- scripts/        # Shell / Python 脚本
|- migrations/            # 数据库 schema / migration
|- scripts/
|  |- init-db.sh          # 本地初始化 queue.db（幂等）
|  \- sqlite.sh           # 自动开启外键约束的 SQLite 包装脚本
|- tags.md                # 全局分层标签体系
|- tag-dataview.md        # 从 tag 视角穿透各层的根级 Dataview 看板
|- vault-language.txt     # brief/knowledge/wisdom/idea 与 tags 的下游输出语言配置
\- wisdom/                # 综合性智慧文章（扁平结构）
   \- AGENTS.md
```

---

## 核心机制

### 门禁机制（Pipeline Gate）

层间推进采用**发布单元（Publish Unit）+ 版本消费**模型，确保下游只在上游完整就绪后才可消费：

- **单文件对象**（如一篇论文）：`single` 类型 unit，包含 1 个 `required` 成员。
- **多成员对象**（如电子书）：`collection` 类型 unit，所有正文章节为 `required`，附录或序言可设为 `optional`。
- 只有所有 required 成员完成后，unit 才能进入 `ready` 状态并被下游消费。

### 双向链接

所有层间关联通过 YAML front matter 中的双向链接维护：

```text
material.brief    <-> brief.material
brief.knowledge   <-> knowledge.briefs
knowledge.wisdoms <-> wisdom.knowledge
```

可使用 `material/skills/scripts/sync-bidirectional-links.py` 自动扫描并补全遗漏的反向链接。

### Vault 语言约定

`vault-language.txt` 用来声明这个 vault 的规范下游输出语言。

- `material/` 保持对原始来源忠实，不强制翻译。
- `brief/`、`knowledge/`、`wisdom/`、`idea/` 的文件名、标题、小节标题、正文以及新增 tag，默认都应遵循 `vault-language.txt`。
- 同一个 vault 不应同时维护中英文两套并列 tag 分支，除非用户明确要求双语输出。
- 如果 vault 不是英文运行模式，应在第一次跑下游之前先改好 `vault-language.txt`。
- tag 应该保持语义化、层级化，不要拿 tag 记录工作流状态；这类信息更适合放在路径或 front matter 字段里。

### 用户偏好约定

`user.md` 用来保存这个 vault 的长期用户偏好。

- 可用于定义稳定的数据源关注方向、排除项、排序规则、下游强调重点和 idea 生成偏好。
- 当前对话里的明确指令优先级高于 `user.md`。
- `user.md` 不能覆盖仓库级 invariant、pipeline gate 或 `tags.md` 的规范。
- 文件路径固定为 `user.md`，但内容可以使用用户自己的语言。

### 幂等性

所有 Agent 操作均应支持重复运行而不产生重复数据：

- 注册前检查路径唯一性
- 内容变更时更新已有记录
- 通过 `ready_version` 记录下游消费版本
- front matter 中避免重复 wikilink

---

## 技术依赖

| 工具 | 用途 |
|---|---|
| `sqlite3` | 操作本地队列数据库 |
| `pandoc` >= 2.x | PDF / EPUB / HTML 转 Markdown |
| `python3` + `pyyaml` | 维护 YAML front matter 与双向链接 |
| `unzip` | 探查 EPUB 内部结构 |

推荐在运行前检查：

```bash
pandoc --version
python3 -c "import yaml; print('pyyaml ok')" || pip3 install pyyaml
```

数据库命令建议统一通过 `./scripts/sqlite.sh` 执行；该脚本会自动对每个 SQLite 连接启用 `PRAGMA foreign_keys=ON`。

---

## 快速开始

1. 在仓库根目录执行 `./scripts/init-db.sh`，生成本地 `queue.db`。
2. 先创建或完善 `user.md`，给 vault 一个稳定的偏好配置。
3. 如果你希望下游输出为英文以外的语言，先修改 `vault-language.txt`。
4. 将原始文件（PDF、EPUB 等）放入 `material/{source}/` 目录。
5. 运行 material 层，完成格式转换和数据库注册。
6. 按顺序触发 `brief -> knowledge -> wisdom / idea`。
7. 定期执行 `python3 material/skills/scripts/sync-bidirectional-links.py --dry-run --root .` 检查双向链接完整性。

> `queue.db` 为本地生成文件，仓库不直接维护该数据库。
>
> 数据库命令请优先使用 `./scripts/sqlite.sh "SQL..."`，不要直接使用裸 `sqlite3 queue.db`。

---

## 扩展方式

- 在 `idea/` 下新增一个带 `AGENTS.md` 的子目录，即可注册新的研究方向。
- 在 `material/{source}/AGENTS.md` 中描述新的数据源插件。
- 将可复用脚本放入 `material/skills/scripts/`，供所有层共享。
- 使用 `SKILL/ambra/SKILL.md` 作为创建新 vault、配置 `user.md`、扩展数据源、导入内容和触发全流程的高层技能入口。
