#!/usr/bin/env bash
# 把本仓库 skills/ 下的 skill 一键同步到各大 agent 平台（macOS / Linux 版）。
# 用法: ./sync.sh [-p <项目路径>]... [-n 预览]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT/skills"

# 全局型平台（用户级 skills 目录）
GLOBAL_PLATFORMS=("$HOME/.workbuddy/skills" "$HOME/.claude/skills")

# 规则型平台：名称|相对规则目录|扩展名|是否带 frontmatter(0/1)
RULE_PLATFORMS=(
  "Cursor|.cursor/rules|mdc|1"
  "Trae|.trae/rules|mdc|1"
  "Codex|.codex/rules|md|0"
  "Gemini|.gemini/rules|md|0"
)

# 填入你的项目路径，或用 -p 指定
PROJECTS=()

DRY=0
while getopts "p:n" o; do
  case $o in
    p) PROJECTS+=("$OPTARG");;
    n) DRY=1;;
    *) echo "Usage: $0 [-p <project>]... [-n]"; exit 1;;
  esac
done

shopt -s nullglob
skills=("$SRC"/*/)
skills=("${skills[@]%/}")
[ ${#skills[@]} -eq 0 ] && { echo "skills/ 下没有 skill。"; exit 0; }

link_skill() {
  local link="$1" src="$2"
  if [ -L "$link" ]; then
    [ $DRY -eq 1 ] && echo "  [dry] 移除旧链接 $link" || rm -f "$link"
  elif [ -e "$link" ]; then
    echo "  跳过：已存在且非链接 -> $link"; return
  fi
  [ $DRY -eq 1 ] && { echo "  [dry] 链接 $link -> $src"; return; }
  ln -sfn "$src" "$link"
  echo "  + 链接 $(basename "$link")"
}

echo "==> 同步 ${#skills[@]} 个 skill"

for target in "${GLOBAL_PLATFORMS[@]}"; do
  mkdir -p "$target"
  echo ">> 全局平台 $target"
  for s in "${skills[@]}"; do
    link_skill "$target/$(basename "$s")" "$s"
  done
done

if [ ${#PROJECTS[@]} -eq 0 ]; then
  echo ">> 规则型平台未配置项目目录，跳过（在 PROJECTS 填入路径，或用 -p 指定）。"
else
  for proj in "${PROJECTS[@]}"; do
    [ -d "$proj" ] || { echo "  项目不存在，跳过：$proj"; continue; }
    echo ">> 项目规则 $proj"
    for entry in "${RULE_PLATFORMS[@]}"; do
      IFS='|' read -r name rel ext fm <<< "$entry"
      rulesDir="$proj/$rel"
      mkdir -p "$rulesDir"
      for s in "${skills[@]}"; do
        body=$(awk 'BEGIN{infm=0} /^---$/{if(infm==0){infm=1;next}else{next}} infm==1{print}' "$s/SKILL.md" 2>/dev/null || true)
        [ -z "$body" ] && body=$(cat "$s/SKILL.md" 2>/dev/null || echo "(无 SKILL.md)")
        if [ "$fm" = "1" ]; then
          content="---\nname: $(basename "$s")\ndescription: $(basename "$s") (synced from personal skill repo)\nalwaysApply: false\n---\n\n$body"
        else
          content="# $(basename "$s")\n\n$body"
        fi
        out="$rulesDir/$(basename "$s").$ext"
        [ $DRY -eq 1 ] && { echo "  [dry] 写 $out"; continue; }
        printf '%s\n' "$content" > "$out"
        echo "  + [$name] $(basename "$s").$ext"
      done
    done
  done
fi
echo "==> 完成。"
