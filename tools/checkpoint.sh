#!/bin/bash
# checkpoint.sh — 游戏日结束强制检查清单（state.yaml 版）
# 用法：bash tools/checkpoint.sh
#
# 每个游戏日结束时必须运行。输出待办清单 + 数据校验 + 触发检查。

STATE="campaign/state.yaml"

echo "═══ 游戏日结束 Checkpoint ═══"
echo ""

if [ ! -f "$STATE" ]; then
    echo "  ❌ state.yaml 不存在"
    exit 1
fi

# ── 读取当前状态 ──

CURRENT_DAY=$(yq '.calendar.day' "$STATE")
LOCATION=$(yq '.calendar.location' "$STATE")

echo "  游戏日: Day ${CURRENT_DAY:-?}"
echo "  位置: ${LOCATION:-?}"
echo ""

# ── 1. 文件同步清单 ──

echo "── 文件同步（逐项确认） ──"
echo "  [ ] state.yaml — 日期/时间/天气/位置/金币/HP/XP/法术位 已更新"
echo "  [ ] quest-log.md — 步骤进度已更新（如有）"
echo "  [ ] companion files — 好感度变动已写入（如有），state.yaml 同步"
echo ""

# ── 2. 好感度快照 ──

echo "── 好感度 ──"
for name in $(yq '.companions | keys | .[]' "$STATE"); do
    val=$(yq ".companions.${name}.affinity.value" "$STATE")
    stage=$(yq ".companions.${name}.affinity.stage" "$STATE")
    printf "  %-8s  好感: %-4s  阶段: %s\n" "$name" "${val:-?}" "${stage:-?}"
done
echo ""

# ── 3. 深度对话冷却 ──

echo "── 深度对话冷却 ──"
for name in $(yq '.deep_dialogue | keys | .[]' "$STATE" 2>/dev/null); do
    next=$(yq ".deep_dialogue.${name}.next_day" "$STATE")
    printf "  %-8s  下次触发: Day %s\n" "$name" "${next:-?}"
done
echo ""

# ── 5. 纪律提醒 ──

echo "── 纪律提醒 ──"
echo "  ❗ 禁止自动推进时间——等待玩家指令（"休息"/"过夜"/"出发"）"
echo "  ❗ 火把/油按实际使用扣减"
echo "  ❗ 长休恢复: HP全满 + 恢复一半Hit Dice + 法术位全恢复"
echo ""

# ── 6. 数据一致性校验 ──

echo "── 数据校验 ──"
bash tools/lint.sh

echo ""
echo "═══ Checkpoint 完成 ═══"
