#!/bin/bash
# D&D 5e 怪物快速查询工具
# 用法:
#   lookup-monster.sh goblin              # 英文
#   lookup-monster.sh 哥布林              # 中文
#   lookup-monster.sh wolf                # 模糊搜索

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MM_FILE="$PROJECT_DIR/rules/5e-mm.md"

if [ -z "$1" ]; then
  echo "用法: bash tools/lookup-monster.sh \"怪物名\""
  echo "  支持英文、中文或模糊搜索"
  exit 1
fi

if [ ! -f "$MM_FILE" ]; then
  echo "❌ 怪物文件不存在: $MM_FILE"
  exit 1
fi

QUERY="$1"

# Find matching ### headers
matches=()
match_lines=()

while IFS= read -r line; do
  lineno="${line%%:*}"
  content="${line#*:}"
  if [[ "$content" =~ ^###\  ]]; then
    monster_title="${content#\#\#\# }"
    if echo "$monster_title" | grep -qi "$QUERY"; then
      matches+=("$monster_title")
      match_lines+=("$lineno")
    fi
  fi
done < <(grep -n '^### ' "$MM_FILE")

if [ ${#matches[@]} -eq 0 ]; then
  echo "❌ 未找到 \"$QUERY\"，请检查拼写"
  echo "  提示: 用英文片段模糊搜索，如 bash tools/lookup-monster.sh wolf"
  exit 1
fi

if [ ${#matches[@]} -gt 5 ]; then
  echo "🔍 找到 ${#matches[@]} 个匹配项（显示前 10 个）："
  for i in "${!matches[@]}"; do
    [ "$i" -ge 10 ] && break
    echo "  $((i+1)). ${matches[$i]}  (L${match_lines[$i]})"
  done
  if [ ${#matches[@]} -gt 10 ]; then
    echo "  ... 还有 $((${#matches[@]} - 10)) 个结果"
  fi
  echo ""
  echo "  请用更精确的名称重新搜索"
  exit 0
fi

if [ ${#matches[@]} -gt 1 ]; then
  echo "🔍 找到 ${#matches[@]} 个匹配项："
  echo ""
fi

total_lines=$(wc -l < "$MM_FILE")

for i in "${!matches[@]}"; do
  line_num="${match_lines[$i]}"
  monster_name="${matches[$i]}"

  # Find section ref
  section_ref=$(head -n "$line_num" "$MM_FILE" | grep -E '^## [0-9]+\.' | tail -1 | sed 's/^## //')

  # Read block: next line is CR/XP line, then AC/HP/Speed, then stats
  end_line=$((line_num + 30))
  [ "$end_line" -gt "$total_lines" ] && end_line="$total_lines"

  block=""
  while IFS= read -r bline; do
    if [[ "$bline" == "---" ]] || [[ "$bline" =~ ^### ]]; then
      break
    fi
    block+="$bline"$'\n'
  done < <(sed -n "$((line_num+1)),${end_line}p" "$MM_FILE")

  # Extract 5e fields
  cr_line=$(echo "$block" | grep -E '^CR ' | head -1)
  ac_hp_line=$(echo "$block" | grep -E '^AC:' | head -1)

  # Extract CR and XP
  cr=$(echo "$cr_line" | grep -oE 'CR [0-9/]+' | head -1 | sed 's/CR //')
  xp=$(echo "$cr_line" | grep -oE 'XP [0-9,]+' | head -1 | sed 's/XP //')

  # Extract AC, HP, Speed
  ac=$(echo "$ac_hp_line" | grep -oE 'AC: [0-9]+' | sed 's/AC: //')
  hp=$(echo "$ac_hp_line" | sed 's/.*HP: //' | sed 's/&nbsp.*//' | sed 's/  .*//' | head -1)
  speed=$(echo "$ac_hp_line" | sed 's/.*Speed: //' | head -1)

  # Extract actions
  actions=$(echo "$block" | sed -n 's/^\*\*【行动】\*\*[：:][[:space:]]*//p' | head -1)
  if [ -z "$actions" ]; then
    actions=$(echo "$block" | grep -A1 '【行动】' | tail -1 | sed 's/^[[:space:]]*//')
  fi

  echo "👹 $monster_name — rules/5e-mm.md §${section_ref}"
  echo "  CR: ${cr:-?} | XP: ${xp:-?}"
  echo "  AC: ${ac:-?} | HP: ${hp:-?} | Speed: ${speed:-?}"
  if [ -n "$actions" ] && [ "$actions" != "" ]; then
    echo "  行动: $actions"
  fi
  echo "  📖 详见 rules/5e-mm.md L${line_num}"

  if [ ${#matches[@]} -gt 1 ] && [ "$i" -lt $((${#matches[@]}-1)) ]; then
    echo ""
  fi
done
