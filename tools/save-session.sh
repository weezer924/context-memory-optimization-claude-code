#!/bin/bash
# save-session.sh — Session 结束存档检查清单
# 用法：bash tools/save-session.sh [session_number]
#
# 输出一份存档审计清单，列出所有需要更新的文件和检查项。
# DM 逐项确认后再结束 Session。

SESSION_NUM=${1:-"?"}

echo "═══════════════════════════════════════════════════════"
echo "  SESSION $SESSION_NUM 存档检查清单"
echo "═══════════════════════════════════════════════════════"
echo ""

STATE="campaign/state.yaml"
if [ -f "$STATE" ]; then
    CURRENT_DAY=$(yq '.calendar.day' "$STATE")
    LOCATION=$(yq '.calendar.location' "$STATE")
    echo "  当前游戏日: Day ${CURRENT_DAY:-?}"
    echo "  当前位置: ${LOCATION:-?}"
else
    echo "  ⚠️ state.yaml 不存在"
fi

echo ""
echo "───────────────────────────────────────────────────────"
echo "  1. XP 结算"
echo "───────────────────────────────────────────────────────"
echo "  [ ] 怪物 XP（按 CR 查 rules/5e-mm.md §2）"
echo "  [ ] 总 XP ÷ 队伍人数（均分）"
echo "  [ ] 检查是否升级（见 rules/5e-phb.md §1.10）"
echo ""

echo "───────────────────────────────────────────────────────"
echo "  2. 必须更新的文件"
echo "───────────────────────────────────────────────────────"
echo "  [ ] sessions/logs/session-${SESSION_NUM}.md  ← 本次记录+XP明细"
echo "  [ ] campaign/state.yaml                         ← 所有数值更新（HP/XP/金币/物品/日期/好感度）"
echo "  [ ] campaign/pcs/pc.md                           ← PC 叙事内容更新（如有）"
echo "  [ ] campaign/quest-log.md                        ← 任务步骤打勾/新任务"
echo ""

echo "───────────────────────────────────────────────────────"
echo "  3. 按需更新的文件"
echo "───────────────────────────────────────────────────────"
echo "  [ ] campaign/companions/*.md       ← 好感度/对话记录"
echo "  [ ] 当前区域 npcs.md               ← 新NPC/互动记录/印象变化"
echo "  [ ] 当前区域 shops.md              ← 商店库存变化（大量交易后）"
echo "  [ ] sessions/dm-notes.md           ← 下次开场/待检事件/伏笔追踪/涟漪种子"
echo "  [ ] sessions/dm-revealed-info.md   ← 玩家已知/未知信息更新"
echo ""

echo "───────────────────────────────────────────────────────"
echo "  4. 记忆更新"
echo "───────────────────────────────────────────────────────"
echo "  [ ] .claude/story-flags.md           ← 新增/更新 Story Flags"
echo "  [ ] MEMORY.md                        ← 操作教训/设计决策（如有，禁止写数值）"
echo ""

echo "───────────────────────────────────────────────────────"
echo "  5. 一致性检查"
echo "───────────────────────────────────────────────────────"
echo "  [ ] state.yaml 好感度值与各 companion 文件一致"
echo "  [ ] state.yaml 金币/物品算术正确（逐笔验证）"
echo "  [ ] 消耗品已扣除（火把/油按实际使用）"
echo "  [ ] 法术位已重置（如果过了长休息）"
echo ""

# 运行好感度状态检查
echo "───────────────────────────────────────────────────────"
echo "  6. 当前好感度快照"
echo "───────────────────────────────────────────────────────"
for name in $(yq '.companions | keys | .[]' "$STATE" 2>/dev/null); do
    val=$(yq ".companions.${name}.affinity.value" "$STATE" 2>/dev/null)
    stage=$(yq ".companions.${name}.affinity.stage" "$STATE" 2>/dev/null)
    printf "  %-8s  好感: %-4s  阶段: %s\n" "$name" "${val:-?}" "${stage:-?}"
done

echo ""

echo "───────────────────────────────────────────────────────"
echo "  7. 数据一致性校验"
echo "───────────────────────────────────────────────────────"
bash tools/lint.sh
echo ""

echo "═══════════════════════════════════════════════════════"
echo "  全部确认后，Session $SESSION_NUM 存档完成。"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  状态面板: http://localhost:8081"
