# skills

我个人专用的 **agent skill 仓库**。所有 skill 集中维护在这里（单一真相源），用一条命令就能同步到各大 agent 平台。

## 目录结构

```
skills/                      # 规范化的 skill 源（git 跟踪，单一真相源）
  lark-unified/
  obsidian/
sync.ps1                    # Windows：一键同步到各平台
sync.sh                     # macOS / Linux：一键同步到各平台
```

每个 skill 至少包含 `SKILL.md`（必需），可附 `references/`、`scripts/`、`_icon.*`、`_skillhub_meta.json`。

## 同步原理

两类平台，处理方式不同：

- **全局型（软链）**：WorkBuddy、Claude Code 这类有「用户级 skills 目录」的，直接把 `skills/<name>` 软链（Windows 用 junction，macOS/Linux 用 symlink）到用户目录，所有工作区/项目都自动可用。
- **规则型（转规则文件）**：Cursor、Trae、Codex、Gemini 这类「规则是项目级」的，把 `SKILL.md` 转成对应平台的规则文件，写入**各项目的规则目录**。因为规则属于具体项目，所以需要在脚本里指定项目路径。

## 使用方法

```powershell
# Windows
.\sync.ps1                 # 同步全局平台（WorkBuddy / Claude Code），并把规则写入已配置的项目
.\sync.ps1 -Project C:\Code\MyProject   # 额外把规则写入某个项目
.\sync.ps1 -WhatIf         # 只预览，不写盘
```

```bash
# macOS / Linux
./sync.sh
./sync.sh -p /path/to/MyProject
./sync.sh -n              # 预览
```

同步是**幂等**的：重复执行只会更新，不会重复创建。

## 加一个新 skill

1. 在 `skills/` 下新建目录，放入 `SKILL.md`（参考现有 skill 的结构）。
2. 跑一次 `sync.ps1` 重新链接即可。

## 加一个 agent 平台 / 项目

- **全局型**：在 `sync.ps1` 的 `$GlobalPlatforms` / `sync.sh` 的 `GLOBAL_PLATFORMS` 里加一行目标目录。
- **规则型**：在 `$RulePlatforms` / `RULE_PLATFORMS` 里加 `名称 | 规则目录 | 扩展名 | 是否带 frontmatter`。
- **项目**：在 `sync.ps1` 的 `$Projects` 里填项目路径，或每次用 `-Project` / `-p` 临时指定。

## 说明

- 规则型平台的文件格式（如 Cursor 的 `.mdc`、Codex/Gemini 的规则目录）随各平台版本演进，脚本里用的是当前通用写法；若你的版本有差异，改 `$RulePlatforms` 里的 `Ext` / `Frontmatter` 即可。
- Trae 的规则目录默认按 `.trae/rules` 处理，若你的客户端不同，请在配置里调整。

## 现有 skill

| skill         | 说明                              |
|---------------|-----------------------------------|
| lark-unified  | 统一飞书 / Lark CLI（命令、文档、表格、审批等） |
| obsidian      | Obsidian 仓库的读写与笔记管理      |
