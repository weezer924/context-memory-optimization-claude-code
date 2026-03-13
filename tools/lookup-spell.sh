#!/bin/bash
# D&D 5e 法术快速查询工具
# 用法:
#   lookup-spell.sh "Magic Missile"      # 英文精确
#   lookup-spell.sh "魔法飞弹"            # 中文精确
#   lookup-spell.sh missile               # 模糊搜索

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SPELL_FILE="$PROJECT_DIR/rules/5e-spells.md"

if [ -z "$1" ]; then
  echo "用法: bash tools/lookup-spell.sh \"法术名\""
  echo "  支持英文、中文或模糊搜索"
  exit 1
fi

if [ ! -f "$SPELL_FILE" ]; then
  echo "❌ 法术文件不存在: $SPELL_FILE"
  exit 1
fi

QUERY="$1"

# 5e spell format uses **Bold Name** for spell entries (under ## Spell Descriptions)
# Find matching **SpellName** lines
matches=()
match_lines=()

while IFS= read -r line; do
  lineno="${line%%:*}"
  content="${line#*:}"
  # Match lines that are bold spell names: **Spell Name**
  if [[ "$content" =~ ^\*\*.*\*\*$ ]]; then
    spell_title=$(echo "$content" | sed 's/^\*\*//;s/\*\*$//')
    if echo "$spell_title" | grep -qi "$QUERY"; then
      matches+=("$spell_title")
      match_lines+=("$lineno")
    fi
  fi
done < <(grep -n '^\*\*[A-Z].*\*\*$' "$SPELL_FILE")

if [ ${#matches[@]} -eq 0 ]; then
  echo "❌ 未找到 \"$QUERY\"，请检查拼写"
  echo "  提示: 用英文片段模糊搜索，如 bash tools/lookup-spell.sh cure"
  exit 1
fi

# If too many matches, just list
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

# Helper: extract field from 5e spell format
# Format: **Field:** Value
extract_field() {
  local lines="$1"
  local field="$2"
  echo "$lines" | sed -n "s/^\*\*${field}:\*\*[[:space:]]*\(.*\)/\1/p" | head -1 | sed 's/[[:space:]]*$//'
}

# Display each match's details
for i in "${!matches[@]}"; do
  line_num="${match_lines[$i]}"
  spell_name="${matches[$i]}"

  # Read the next 8 lines for spell details
  detail_lines=$(sed -n "$((line_num+1)),$((line_num+8))p" "$SPELL_FILE")

  # School/level line (italic): *School Cantrip/Level (Classes)*
  school_line=$(echo "$detail_lines" | grep '^\*[A-Z]' | head -1 | sed 's/^\*//;s/\*$//')

  cast_time=$(extract_field "$detail_lines" "Casting Time")
  range=$(extract_field "$detail_lines" "Range")
  components=$(extract_field "$detail_lines" "Components")
  duration=$(extract_field "$detail_lines" "Duration")

  # Get spell description (first non-metadata line)
  effect=$(echo "$detail_lines" | grep -v '^\*\*\|^\*[A-Z]\|^$' | head -1)

  echo "📜 $spell_name"
  if [ -n "$school_line" ]; then
    echo "  $school_line"
  fi
  echo "  施法时间: ${cast_time:-?} | 射程: ${range:-?}"
  echo "  成分: ${components:-?} | 持续: ${duration:-?}"
  if [ -n "$effect" ]; then
    # Truncate long descriptions
    if [ ${#effect} -gt 120 ]; then
      echo "  效果: ${effect:0:117}..."
    else
      echo "  效果: $effect"
    fi
  fi
  echo "  📖 详见 rules/5e-spells.md L${line_num}"

  if [ ${#matches[@]} -gt 1 ] && [ "$i" -lt $((${#matches[@]}-1)) ]; then
    echo ""
  fi
done
