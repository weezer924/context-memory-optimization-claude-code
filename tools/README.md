# DM 工具箱 — 玩家快速参考

## 游戏流程口令

### 开场

直接开始对话即可，DM 会自动读取所有状态文件。无需特殊口令。

### 游戏中

| 口令                                | 效果                                                                  |
| ----------------------------------- | --------------------------------------------------------------------- |
| **"存档"** / **"checkpoint"**       | 触发轻量存档（同步 state.yaml / 好感度），不中断游戏                  |
| **"查好感"** / **"好感度"**         | DM 报告所有在队队友的当前好感值和阶段                                 |
| **"检查一致性"** / **"lint"**       | 运行数据校验，检查跨文件数值是否同步                                  |
| **"结束 session"** / **"存档结束"** | 触发完整 Session 存档（含 XP 结算、全文件同步、一致性校验、快照生成） |

### Session 结束

告诉 DM **"结束 session N"**（N 为 Session 编号），DM 会：

1. 运行 `save-session.sh N` 输出存档清单
2. 逐项完成 XP 结算、文件更新
3. 自动运行数据校验（lint）

---

## 工具脚本详情

### `roll.sh` — 掷骰

```bash
bash tools/roll.sh d20        # 攻击/豁免
bash tools/roll.sh 3d6        # 属性
bash tools/roll.sh d8+2       # 伤害+修正
bash tools/roll.sh d100       # 百分比
```

> DM 自动使用，玩家无需手动调用。

### `lint.sh` — 数据一致性校验

```bash
bash tools/lint.sh
```

检查 4 项跨文件数值：

| 检查项   | 来源 A         | 来源 B         |
| -------- | -------------- | -------------- |
| 好感度值 | companion 文件 | state.yaml     |
| PC XP    | state.yaml     | — (内部一致性) |
| 队友 XP  | companion 文件 | state.yaml     |
| 游戏日   | state.yaml     | — (内部一致性) |

输出 `✅ PASS` 或 `❌ MISMATCH`。exit 0 = 全通过。

### `checkpoint.sh` — 轻量存档

```bash
bash tools/checkpoint.sh
```

游戏中途自动触发。输出同步清单 + 好感度快照 + 数据校验。

### `save-session.sh` — 完整 Session 存档

```bash
bash tools/save-session.sh 9    # Session 9 存档
```

输出完整存档清单（XP 结算 → 文件更新 → 好感快照 → 数据校验 → 状态快照）。

### `lookup-spell.sh` — 法术查询

```bash
bash tools/lookup-spell.sh "Magic Missile"    # 英文精确
bash tools/lookup-spell.sh "魔法飞弹"          # 中文精确
bash tools/lookup-spell.sh missile             # 模糊搜索（列出匹配项）
```

返回法术学派/职业、施法时间、射程、成分、持续时间、效果摘要 + 行号引用。

> DM 在施法裁定时自动调用，替代 Read 整个 `5e-spells.md`。

### `lookup-monster.sh` — 怪物查询

```bash
bash tools/lookup-monster.sh goblin            # 英文
bash tools/lookup-monster.sh 哥布林            # 中文
bash tools/lookup-monster.sh wolf              # 模糊（匹配 Wolf/Worg/Dire Wolf/Winter Wolf）
```

返回 CR、XP、AC、HP、Speed、行动摘要 + 行号引用。

> DM 在遭遇/战斗中自动调用，替代 Read 整个 `5e-mm.md`。

### `encounter.sh` — 遭遇生成器

```bash
bash tools/encounter.sh kel-konig --force     # 强制遭遇（跳过 d6 判定）
bash tools/encounter.sh glacier --weather     # 含天气掷骰
bash tools/encounter.sh forest               # 蛮荒边境林地
bash tools/encounter.sh vale                 # 地下城：暗影之谷
```

区域列表：

| 参数           | 区域                 | 骰子 |
| -------------- | -------------------- | ---- |
| `kel-konig`    | 凯尔-科尼格周边/湖区 | d12  |
| `glacier`      | 冰川区域/灰矮人前哨  | d12  |
| `kuldahar`     | 库达哈山隘/山区      | d12  |
| `vale`         | 暗影之谷 (地下城)    | d8   |
| `severed-hand` | 断手要塞 (地下城)    | d8   |
| `dorns-deep`   | 多恩深渊 (地下城)    | d8   |
| `forest`       | 蛮荒边境·林地        | d6   |
| `road`         | 蛮荒边境·道路        | d6   |
| `goblin`       | 蛮荒边境·哥布林要塞  | d6   |

选项：`--force`（跳过遭遇判定）、`--weather`（掷天气，仅 IWD）

> DM 在野外旅行/地下城探索时自动调用。

### `combat.sh` — 战斗辅助

```bash
bash tools/combat.sh init 2 -1 3                       # 先攻（d20+DEX mod，高先）
bash tools/combat.sh attack 5 15 1d8+3                 # 攻击：+5 攻击加值, AC 15, 1d8+3 伤害
bash tools/combat.sh save 3 15                         # 豁免判定（+3 加值, DC 15）
bash tools/combat.sh conc 18                           # 专注检定（受到 18 伤害，计算 DC）
bash tools/combat.sh dist 0,0 3,4                      # 网格距离（两点间 ft）
bash tools/combat.sh aoe sphere 20 5,5                 # AoE 覆盖范围
bash tools/combat.sh range 80/320 100                  # 远程判定（正常/劣势/不可）
```

> DM 在战斗中自动调用。自然 20 = 暴击（伤害骰翻倍），自然 1 = 自动失手。


> 不自动写入文件。DM 确认后手动同步。

---

## 自动触发时机

以下由 DM 在游戏中自动执行，玩家无需操心：

| 时机                           | 自动执行                     |
| ------------------------------ | ---------------------------- |
| 任何掷骰                       | `roll.sh`                    |
| 好感度变化                     | DM 直接裁定（不再使用脚本） |
| 野外旅行/地下城探索            | `encounter.sh`               |
| 法术详情查询                   | `lookup-spell.sh`            |
| 怪物数据查询                   | `lookup-monster.sh`          |
| 专注检定                       | `combat.sh conc`             |
| 战斗（先攻/攻击/豁免）          | `combat.sh`                  |
| 每 ≥3 游戏日 或 ≥3 重大事件    | `checkpoint.sh`（含 lint）   |
| Session 结束                   | `save-session.sh`（含 lint） |
