# workbuddy-skills

我自己维护的 WorkBuddy skill 集合。目标：**版本可控、跨机器同步、可分享社区**。

## 目录结构

```
.workbuddy/skills/
├── lark-unified/      # 统一飞书 / Lark CLI 操作
└── obsidian/          # Obsidian 仓库读写
```

每个 skill 至少包含 `SKILL.md`（必需），可附 `references/`、`scripts/`、`_icon.*`、`_skillhub_meta.json`。

## 工作原理（dotfiles 模式）

skill 的**实体文件**就放在本仓库里（受 git 管理，单一真相源）。
在用户级目录 `%USERPROFILE%\.workbuddy\skills\` 下为每个 skill 建立一个**目录 junction**，
指回本仓库里的对应文件夹。这样 WorkBuddy 在任意项目里都能加载这些 skill，
而真实文件只维护一份、改一处处处生效。

建立 junction（Windows PowerShell，无需管理员权限）：

```powershell
$src = "C:\Code\AI\Skills\.workbuddy\skills"
$dst = "$env:USERPROFILE\.workbuddy\skills"
foreach ($name in (Get-ChildItem $src -Directory).Name) {
    $link = Join-Path $dst $name
    if (Test-Path $link) { Remove-Item $link -Force -Recurse }
    New-Item -ItemType Junction -Path $link -Target (Join-Path $src $name)
}
```

> 提示：用 junction（而非 `mklink /D` 符号链接）是为了免管理员权限，且对 WorkBuddy 完全透明。

## 换一台机器初始化

```bash
git clone <本仓库地址> C:\Code\AI\Skills
```

然后按上面的 PowerShell 片段重建 junction 即可。

## 日常维护

```bash
cd C:\Code\AI\Skills
git add -A
git commit -m "更新 xxx skill"
git push
```

> 若通过 WorkBuddy 的 skill 市场更新了某个 skill，改动会直接落到本仓库（因为 junction 是透明的），
> 记得回来 `git commit` 一下。

## 分享给社区

把想公开的 skill 通过 WorkBuddy 的 skill 市场上架即可（本仓库作为源码备份与协作入口）。

## 现有 skill

| skill         | 说明                              |
|---------------|-----------------------------------|
| lark-unified  | 统一飞书 / Lark CLI（命令、文档、表格、审批等） |
| obsidian      | Obsidian 仓库的读写与笔记管理      |
