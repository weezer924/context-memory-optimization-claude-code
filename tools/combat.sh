#!/bin/bash
# D&D 5e 战斗辅助工具
# 用法:
#   combat.sh init <DEX_mod1> [DEX_mod2] ...        先攻（各掷 d20+DEX）
#   combat.sh attack <atk_bonus> <AC> [dmg-dice]    攻击判定
#   combat.sh save <bonus> <DC>                      豁免判定
#   combat.sh conc <damage>                          专注检定（CON 豁免）

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

roll() {
  local result
  result=$("$SCRIPT_DIR/roll.sh" "$1" 2>/dev/null)
  echo "$result" | grep -oE '[0-9]+$'
}

roll_display() {
  "$SCRIPT_DIR/roll.sh" "$1"
}

CMD="$1"
shift

case "$CMD" in

# ─── Initiative ───
init)
  echo "⚔️ 先攻（d20 + DEX mod，高先）"
  i=1
  for dex_mod in "$@"; do
    init_roll=$(roll d20)
    total=$((init_roll + dex_mod))
    echo "  角色$i: d20 → $init_roll + DEX($dex_mod) = $total"
    i=$((i + 1))
  done
  if [ "$#" -eq 0 ]; then
    # No args: just roll one d20
    init_roll=$(roll d20)
    echo "  d20 → $init_roll（加上 DEX 调整值）"
  fi
  ;;

# ─── Attack ───
attack)
  ATK_BONUS="${1:?需要攻击加值}"
  AC="${2:?需要目标 AC}"
  DMG_DICE="$3"

  atk_roll=$(roll d20)
  total=$((atk_roll + ATK_BONUS))

  echo "⚔️ 攻击判定"
  echo "  需要: ≥ AC $AC"
  if [ "$ATK_BONUS" -ne 0 ]; then
    echo "  掷骰: d20 → $atk_roll, +$ATK_BONUS 攻击加值 = $total"
  else
    echo "  掷骰: d20 → $atk_roll"
  fi

  # Natural 20 = critical hit, natural 1 = auto miss
  CRIT=false
  if [ "$atk_roll" -eq 20 ]; then
    echo "  结果: ✅ 自然 20，暴击！"
    HIT=true
    CRIT=true
  elif [ "$atk_roll" -eq 1 ]; then
    echo "  结果: ❌ 自然 1，自动未命中！"
    HIT=false
  elif [ "$total" -ge "$AC" ]; then
    echo "  结果: ✅ 命中！($total ≥ $AC)"
    HIT=true
  else
    echo "  结果: ❌ 未命中 ($total < $AC)"
    HIT=false
  fi

  # Roll damage if hit and dice provided
  if $HIT && [ -n "$DMG_DICE" ]; then
    dmg_result=$(roll_display "$DMG_DICE")
    dmg_value=$(echo "$dmg_result" | grep -oE '[0-9]+$')
    if $CRIT; then
      # Critical hit: roll damage dice again
      crit_extra=$(roll "$DMG_DICE")
      crit_total=$((dmg_value + crit_extra))
      echo "  伤害: $dmg_result + 暴击额外 $crit_extra = $crit_total"
    else
      echo "  伤害: $dmg_result (最终: $dmg_value)"
    fi
  fi
  ;;

# ─── Saving Throw ───
save)
  BONUS="${1:?需要豁免加值}"
  DC="${2:?需要 DC}"

  save_roll=$(roll d20)
  total=$((save_roll + BONUS))

  echo "🛡️ 豁免检定（DC $DC）"
  if [ "$BONUS" -ne 0 ]; then
    echo "  掷骰: d20 → $save_roll + 豁免加值 $BONUS = $total"
  else
    echo "  掷骰: d20 → $save_roll"
  fi

  if [ "$save_roll" -eq 20 ]; then
    echo "  结果: ✅ 自然 20，自动成功！"
  elif [ "$save_roll" -eq 1 ]; then
    echo "  结果: ❌ 自然 1，自动失败！"
  elif [ "$total" -ge "$DC" ]; then
    echo "  结果: ✅ 豁免成功！($total ≥ $DC)"
  else
    echo "  结果: ❌ 豁免失败 ($total < $DC)"
  fi
  ;;

# ─── Concentration Check ───
conc)
  DAMAGE="${1:?需要受到的伤害值}"
  half=$((DAMAGE / 2))
  DC=10
  [ "$half" -gt "$DC" ] && DC="$half"
  [ "$DC" -gt 30 ] && DC=30

  echo "⚡ 专注检定（CON 豁免）"
  echo "  受到伤害: $DAMAGE → DC = max(10, $DAMAGE/2) = $DC（上限30）"
  echo "  ⚠️ 请用 combat.sh save <CON豁免加值> $DC 掷骰"
  ;;

# ─── Distance (grid) ───
dist)
  P1="${1:?需要第一个坐标 x1,y1}"
  P2="${2:?需要第二个坐标 x2,y2}"

  x1=$(echo "$P1" | cut -d, -f1)
  y1=$(echo "$P1" | cut -d, -f2)
  x2=$(echo "$P2" | cut -d, -f1)
  y2=$(echo "$P2" | cut -d, -f2)

  dx=$(( x2 - x1 ))
  dy=$(( y2 - y1 ))
  [ "$dx" -lt 0 ] && dx=$(( -dx ))
  [ "$dy" -lt 0 ] && dy=$(( -dy ))

  # 5e grid distance: max(dx,dy) * 5ft
  if [ "$dx" -gt "$dy" ]; then
    dist_ft=$(( dx * 5 ))
  else
    dist_ft=$(( dy * 5 ))
  fi

  echo "📏 网格距离"
  echo "  ($x1,$y1) → ($x2,$y2)"
  echo "  格数: 横${dx} 纵${dy} → 距离: ${dist_ft}ft"
  ;;

# ─── AoE coverage ───
aoe)
  SHAPE="${1:?需要形状 (sphere/cube/cone/line/cylinder)}"
  SIZE="${2:?需要尺寸 (ft)}"
  ORIGIN="${3:?需要原点 x,y}"

  ox=$(echo "$ORIGIN" | cut -d, -f1)
  oy=$(echo "$ORIGIN" | cut -d, -f2)
  radius=$(( SIZE / 5 ))

  echo "💥 AoE 覆盖范围"
  echo "  形状: $SHAPE | 尺寸: ${SIZE}ft | 原点: ($ox,$oy)"

  case "$SHAPE" in
    sphere|cylinder)
      echo "  半径: ${SIZE}ft = ${radius}格"
      echo "  覆盖: 以($ox,$oy)为中心，${radius}格半径内所有格子"
      echo "  ⚠️ 检查范围内所有生物（含友军）"
      ;;
    cube)
      echo "  边长: ${SIZE}ft = ${radius}格"
      echo "  覆盖: 从($ox,$oy)起 ${radius}×${radius}格区域"
      echo "  ⚠️ 检查范围内所有生物（含友军）"
      ;;
    cone)
      echo "  长度: ${SIZE}ft, 末端宽度: ${SIZE}ft"
      echo "  覆盖: 从($ox,$oy)扇形展开，每5ft宽度+5ft"
      echo "  ⚠️ 检查范围内所有生物（含友军）"
      ;;
    line)
      echo "  长度: ${SIZE}ft, 宽度: 5ft"
      echo "  覆盖: 从($ox,$oy)到目标点的直线"
      echo "  ⚠️ 检查范围内所有生物（含友军）"
      ;;
    *)
      echo "  ❌ 未知形状: $SHAPE (可用: sphere/cube/cone/line/cylinder)"
      ;;
  esac
  ;;

# ─── Range check ───
range)
  WEAPON_RANGE="${1:?需要武器射程 (如 80/320 或 150)}"
  DISTANCE="${2:?需要实际距离 (ft)}"

  # Parse normal/long range
  if echo "$WEAPON_RANGE" | grep -q '/'; then
    NORMAL=$(echo "$WEAPON_RANGE" | cut -d/ -f1)
    LONG=$(echo "$WEAPON_RANGE" | cut -d/ -f2)
  else
    NORMAL="$WEAPON_RANGE"
    LONG="$WEAPON_RANGE"
  fi

  echo "🏹 远程判定"
  echo "  武器射程: ${NORMAL}/${LONG}ft | 目标距离: ${DISTANCE}ft"

  if [ "$DISTANCE" -le "$NORMAL" ]; then
    echo "  结果: ✅ 正常射程（无惩罚）"
  elif [ "$DISTANCE" -le "$LONG" ]; then
    echo "  结果: ⚠️ 超正常射程 → 攻击掷骰**劣势**"
  else
    echo "  结果: ❌ 超出最大射程 → 无法攻击"
  fi
  ;;

# ─── Help ───
*)
  echo "D&D 5e 战斗辅助工具"
  echo ""
  echo "用法:"
  echo "  combat.sh init <DEX_mod1> [DEX_mod2] ...        先攻（d20+DEX，高先）"
  echo "  combat.sh attack <atk_bonus> <AC> [dmg-dice]    攻击判定"
  echo "  combat.sh save <bonus> <DC>                      豁免判定（d20+bonus ≥ DC）"
  echo "  combat.sh conc <damage>                          专注检定（计算 DC）"
  echo "  combat.sh dist <x1,y1> <x2,y2>                  网格距离"
  echo "  combat.sh aoe <形状> <尺寸ft> <原点x,y>          AoE 覆盖"
  echo "  combat.sh range <正常/远程> <距离ft>             远程判定"
  echo ""
  echo "示例:"
  echo "  combat.sh init 2 -1 3            # 三个角色先攻（DEX mod +2, -1, +3）"
  echo "  combat.sh attack 5 15 1d8+3      # +5 攻击 AC 15，命中掷 1d8+3"
  echo "  combat.sh save 3 15              # 豁免加值 +3，DC 15"
  echo "  combat.sh conc 18                # 受到 18 点伤害的专注检定 DC"
  echo "  combat.sh dist 0,0 3,4           # (0,0)到(3,4)的网格距离"
  echo "  combat.sh aoe sphere 20 5,5      # 20ft球体以(5,5)为中心"
  echo "  combat.sh range 80/320 100       # 80/320射程，距离100ft"
  ;;
esac
