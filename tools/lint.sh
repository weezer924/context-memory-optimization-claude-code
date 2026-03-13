#!/bin/bash
# lint.sh — 数据一致性校验（state.yaml 版）
# 用法：bash tools/lint.sh
#
# 检查 state.yaml 内部一致性 + companion 文件好感度匹配。
# 输出 ✅ PASS 或 ❌ MISMATCH，exit 0（全通过）或 1（有不一致）。

STATE="campaign/state.yaml"
COMPANIONS_DIR="campaign/companions"
PC="campaign/pcs/pc.md"

ERRORS=0

echo "═══ 数据一致性校验 ═══"
echo ""

if [ ! -f "$STATE" ]; then
    echo "  ❌ state.yaml 不存在"
    exit 1
fi

# ────────────────────────────────────────
# 检查 1：好感度（state.yaml vs companion 文件）
# ────────────────────────────────────────
echo "── 好感度 ──"

for name in $(yq '.companions | keys | .[]' "$STATE"); do
    # 跳过不在队伍中的队友（有 status 字段 = 离队/被掳/分离等）
    comp_status=$(yq ".companions.${name}.status // \"\"" "$STATE")
    if [ -n "$comp_status" ]; then
        echo "  ⏭️  $name — 不在队伍中（$comp_status），跳过"
        continue
    fi

    # state.yaml 值
    state_val=$(yq ".companions.${name}.affinity.value" "$STATE")

    # companion 文件值
    comp_file="$COMPANIONS_DIR/${name}.md"
    if [ ! -f "$comp_file" ]; then
        echo "  ⚠️  $name — companion 文件不存在"
        continue
    fi
    comp_val=$(grep '当前值' "$comp_file" | head -1 | sed 's/.*当前值[：:][[:space:]]*//' | tr -d ' ')

    if [ -z "$state_val" ] || [ -z "$comp_val" ]; then
        echo "  ⚠️  $name — 无法提取好感度值（state=$state_val comp=$comp_val）"
        continue
    fi

    if [ "$state_val" = "$comp_val" ]; then
        echo "  ✅ PASS      $name 好感度: $state_val"
    else
        echo "  ❌ MISMATCH  $name 好感度: state.yaml=$state_val  companion=$comp_val"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""

# ────────────────────────────────────────
# 检查 2：PC XP（state.yaml 内部一致性）
# ────────────────────────────────────────
echo "── PC XP ──"

state_xp_cur=$(yq '.pc.xp[0]' "$STATE")
state_xp_max=$(yq '.pc.xp[1]' "$STATE")

if [ -n "$state_xp_cur" ] && [ "$state_xp_cur" != "null" ]; then
    echo "  ✅ PASS      PC XP: ${state_xp_cur}/${state_xp_max}"
else
    echo "  ❌ ERROR     PC XP: state.yaml 中无值"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# ────────────────────────────────────────
# 检查 3：游戏日
# ────────────────────────────────────────
echo "── 游戏日 ──"

state_day=$(yq '.calendar.day' "$STATE")

if [ -n "$state_day" ] && [ "$state_day" != "null" ]; then
    echo "  ✅ PASS      游戏日: Day $state_day"
else
    echo "  ❌ ERROR     游戏日: state.yaml 中无值"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# ────────────────────────────────────────
# 检查 4：队友 XP（state.yaml vs companion 文件）
# ────────────────────────────────────────
echo "── 队友 XP ──"

for name in $(yq '.companions | keys | .[]' "$STATE"); do
    # 跳过不在队伍中的队友
    comp_status=$(yq ".companions.${name}.status // \"\"" "$STATE")
    if [ -n "$comp_status" ]; then
        echo "  ⏭️  $name — 不在队伍中（$comp_status），跳过"
        continue
    fi

    # state.yaml XP (internal consistency check)
    xp_type=$(yq ".companions.${name}.xp | type" "$STATE")
    if [ "$xp_type" = "!!seq" ]; then
        s_cur=$(yq ".companions.${name}.xp[0]" "$STATE")
        s_max=$(yq ".companions.${name}.xp[1]" "$STATE")
        state_xp="${s_cur}/${s_max}"
    else
        state_xp=""
        for cls in $(yq ".companions.${name}.xp | keys | .[]" "$STATE" 2>/dev/null); do
            s_cur=$(yq ".companions.${name}.xp.${cls}[0]" "$STATE")
            s_max=$(yq ".companions.${name}.xp.${cls}[1]" "$STATE")
            prefix=$(echo "$cls" | head -c 1)
            state_xp="${state_xp}${prefix}${s_cur}/${s_max}"
        done
    fi

    if [ -n "$state_xp" ] && [ "$state_xp" != "null" ]; then
        echo "  ✅ PASS      $name XP: $state_xp"
    else
        echo "  ❌ ERROR     $name XP: state.yaml 中无值"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "═══ 校验完成：$ERRORS 项不一致 ═══"

exit $ERRORS
