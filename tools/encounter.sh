#!/bin/bash
# D&D 5e 遭遇生成器（从 encounters.md 动态读取）
# 用法: encounter.sh <zone> [--force] [--weather]
#
# Zones:
#   kel-konig    凯尔-科尼格周边/湖区        (d12, IWD)
#   glacier      冰川区域/灰矮人前哨          (d12, IWD)
#   kuldahar     库达哈山隘/山区              (d12, IWD)
#   vale         暗影之谷 (地下城)            (d8,  IWD)
#   severed-hand 断手要塞 (地下城)           (d8,  IWD)
#   dorns-deep   多恩深渊 (地下城)            (d8,  IWD)
#   forest       蛮荒边境·林地               (d6)
#   road         蛮荒边境·道路               (d6)
#   goblin       蛮荒边境·哥布林要塞          (d6)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

IWD_ENC="$PROJECT_DIR/campaign/world/icewind-dale/encounters.md"
SF_ENC="$PROJECT_DIR/campaign/world/savage-frontier/encounters.md"

roll() {
  local result
  result=$("$SCRIPT_DIR/roll.sh" "$1" 2>/dev/null)
  echo "$result" | grep -oE '[0-9]+$'
}

roll_display() {
  "$SCRIPT_DIR/roll.sh" "$1"
}

# --- Zone metadata (mapping only, not campaign data) ---
# Format: display_name|dice|region|file|section_header_pattern
get_zone_info() {
  case "$1" in
    kel-konig)    echo "凯尔-科尼格周边|d12|iwd|$IWD_ENC|凯尔-科尼格" ;;
    glacier)      echo "冰川区域/灰矮人前哨|d12|iwd|$IWD_ENC|冰川区域" ;;
    kuldahar)     echo "库达哈山隘/山区|d12|iwd|$IWD_ENC|库达哈山隘" ;;
    vale)         echo "暗影之谷|d8|iwd|$IWD_ENC|暗影之谷" ;;
    severed-hand) echo "断手要塞|d8|iwd|$IWD_ENC|断手要塞" ;;
    dorns-deep)   echo "多恩深渊|d8|iwd|$IWD_ENC|多恩深渊" ;;
    forest)       echo "蛮荒边境·林地|d6|savage|$SF_ENC|林地边缘" ;;
    road)         echo "蛮荒边境·道路|d6|savage|$SF_ENC|道路遭遇" ;;
    goblin)       echo "蛮荒边境·哥布林要塞|d6|savage|$SF_ENC|哥布林要塞" ;;
    *) echo ""; return 1 ;;
  esac
}

# Parse a markdown table section from encounters.md
# Args: file, section_header_pattern
# Output: one line per data row, pipe-delimited: "roll|name|qty|reaction"
parse_encounter_table() {
  local file="$1"
  local pattern="$2"

  awk -v pat="$pattern" '
    BEGIN { in_section=0; in_table=0; header_seen=0 }
    /^#/ {
      if (in_section && in_table) exit  # hit next section, done
      if ($0 ~ pat) { in_section=1; next }
      else if (in_section) exit
    }
    in_section && /^\|/ {
      # Skip header row and separator row
      if (/---/) { next }
      if (header_seen == 0) { header_seen=1; next }
      in_table=1
      # Parse table row: | col1 | col2 | col3 | col4 |
      gsub(/^[ \t]*\|[ \t]*/, "")   # strip leading |
      gsub(/[ \t]*\|[ \t]*$/, "")   # strip trailing |
      n = split($0, cols, /[ \t]*\|[ \t]*/)
      if (n >= 2) {
        roll_num = cols[1]
        name = cols[2]
        qty = (n >= 3) ? cols[3] : "-"
        reaction = (n >= 4) ? cols[4] : ""
        # Normalize qty
        if (qty == "—" || qty == "" || qty == " ") qty = "-"
        gsub(/^[ \t]+|[ \t]+$/, "", roll_num)
        gsub(/^[ \t]+|[ \t]+$/, "", name)
        gsub(/^[ \t]+|[ \t]+$/, "", qty)
        gsub(/^[ \t]+|[ \t]+$/, "", reaction)
        print roll_num "|" name "|" qty "|" reaction
      }
    }
  ' "$file"
}

# Parse weather table from IWD encounters.md
parse_weather_table() {
  parse_encounter_table "$IWD_ENC" "天气表"
}

# Parse atmosphere table from IWD encounters.md
parse_atmosphere_table() {
  parse_encounter_table "$IWD_ENC" "无遭遇.*氛围"
}

# --- Parse arguments ---
ZONE=""
FORCE=false
WEATHER=false

for arg in "$@"; do
  case "$arg" in
    --force)   FORCE=true ;;
    --weather) WEATHER=true ;;
    -*)        echo "未知选项: $arg"; exit 1 ;;
    *)         ZONE="$arg" ;;
  esac
done

if [ -z "$ZONE" ]; then
  echo "用法: encounter.sh <zone> [--force] [--weather]"
  echo ""
  echo "Zones:"
  echo "  kel-konig      凯尔-科尼格周边/湖区"
  echo "  glacier        冰川区域/灰矮人前哨"
  echo "  kuldahar       库达哈山隘/山区"
  echo "  vale           暗影之谷 (地下城)"
  echo "  severed-hand   断手要塞 (地下城)"
  echo "  dorns-deep     多恩深渊 (地下城)"
  echo "  forest         蛮荒边境·林地"
  echo "  road           蛮荒边境·道路"
  echo "  goblin         蛮荒边境·哥布林要塞"
  echo ""
  echo "选项:"
  echo "  --force        跳过遭遇判定，强制生成遭遇"
  echo "  --weather      掷天气骰（仅 IWD 区域）"
  exit 1
fi

zone_info=$(get_zone_info "$ZONE")
if [ -z "$zone_info" ]; then
  echo "未知区域: $ZONE"
  exit 1
fi

zone_name=$(echo "$zone_info" | cut -d'|' -f1)
zone_dice=$(echo "$zone_info" | cut -d'|' -f2)
zone_region=$(echo "$zone_info" | cut -d'|' -f3)
zone_file=$(echo "$zone_info" | cut -d'|' -f4)
zone_pattern=$(echo "$zone_info" | cut -d'|' -f5)

if [ ! -f "$zone_file" ]; then
  echo "❌ 遭遇表文件不存在: $zone_file"
  exit 1
fi

echo "━━━━━━━━━━ 🎲 遭遇生成 ━━━━━━━━━━"
echo "  区域: $zone_name"

# --- Weather (if requested, IWD only) ---
if $WEATHER; then
  if [ "$zone_region" = "iwd" ]; then
    w_roll=$(roll d6)
    w_mod=0
    w_effective=$w_roll
    if [ "$ZONE" = "glacier" ]; then
      w_mod=1
      w_effective=$((w_roll + 1))
    fi
    [ $w_effective -lt 1 ] && w_effective=1
    [ $w_effective -gt 6 ] && w_effective=6

    w_entry=$(parse_weather_table | sed -n "${w_effective}p")
    w_name=$(echo "$w_entry" | cut -d'|' -f2)
    w_effect=$(echo "$w_entry" | cut -d'|' -f3)

    echo "  ─────────────────────────"
    if [ $w_mod -ne 0 ]; then
      echo "  天气掷骰: d6 → $w_roll (${ZONE} 修正 +${w_mod} = $w_effective)"
    else
      echo "  天气掷骰: d6 → $w_roll"
    fi
    echo "  天气: $w_name"
    echo "  效果: $w_effect"
  else
    echo "  (天气表仅适用于冰风之谷区域)"
  fi
fi

# --- Encounter check ---
echo "  ─────────────────────────"

HAS_ENCOUNTER=false
if $FORCE; then
  echo "  遭遇判定: --force 强制遭遇"
  HAS_ENCOUNTER=true
else
  check=$(roll d6)
  if [ "$check" -le 2 ]; then
    echo "  遭遇判定: d6 → $check ✅ 有遭遇！"
    HAS_ENCOUNTER=true
  else
    echo "  遭遇判定: d6 → $check — 无遭遇"
  fi
fi

if ! $HAS_ENCOUNTER; then
  if [ "$zone_region" = "iwd" ]; then
    atm_roll=$(roll d6)
    atm_entry=$(parse_atmosphere_table | sed -n "${atm_roll}p")
    atm_desc=$(echo "$atm_entry" | cut -d'|' -f2)
    echo "  ─────────────────────────"
    echo "  氛围 (d6 → $atm_roll): $atm_desc"
  else
    echo "  旅途平安，无事发生。"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# --- Roll encounter ---
enc_roll=$(roll "$zone_dice")

# Parse the encounter table and get the rolled entry
entry=$(parse_encounter_table "$zone_file" "$zone_pattern" | sed -n "${enc_roll}p")

if [ -z "$entry" ]; then
  echo "  ❌ 无法从遭遇表读取条目 #$enc_roll（检查 $zone_file）"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
fi

enc_name=$(echo "$entry" | cut -d'|' -f2)
enc_qty_dice=$(echo "$entry" | cut -d'|' -f3)
enc_reaction=$(echo "$entry" | cut -d'|' -f4)

echo "  遭遇掷骰: $zone_dice → $enc_roll"
echo "  遭遇: $enc_name"

# Quantity
if [ "$enc_qty_dice" = "-" ]; then
  echo "  数量: —（非生物遭遇）"
elif [[ "$enc_qty_dice" =~ ^[0-9]+$ ]]; then
  echo "  数量: $enc_qty_dice"
else
  # Clean qty dice string (remove non-dice chars like "3 Duergar + 矿车")
  clean_dice=$(echo "$enc_qty_dice" | grep -oE '[0-9]*d[0-9]+' | head -1)
  if [ -n "$clean_dice" ]; then
    qty_result=$(roll "$clean_dice")
    echo "  数量: $enc_qty_dice → $qty_result"
  else
    echo "  数量: $enc_qty_dice"
  fi
fi

echo "  反应: $enc_reaction"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
