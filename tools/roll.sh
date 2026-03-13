#!/bin/bash
# D&D 5e 掷骰工具
# 用法: roll.sh <表达式>
# 例: roll.sh d20 | roll.sh 3d6 | roll.sh 2d6+1 | roll.sh d100

expr="$1"
if [ -z "$expr" ]; then
  echo "用法: roll.sh <骰子表达式>"
  echo "例: d20, 3d6, 2d8+1, d100"
  exit 1
fi

# 解析 NdM+B 格式
if [[ "$expr" =~ ^([0-9]*)d([0-9]+)([+-][0-9]+)?$ ]]; then
  num="${BASH_REMATCH[1]:-1}"
  sides="${BASH_REMATCH[2]}"
  mod="${BASH_REMATCH[3]:-+0}"

  total=0
  rolls=()
  for ((i=0; i<num; i++)); do
    r=$(( RANDOM % sides + 1 ))
    rolls+=("$r")
    total=$((total + r))
  done
  total=$((total $mod))

  if [ "$num" -eq 1 ] && [ "$mod" = "+0" ]; then
    echo "🎲 d${sides} → ${rolls[0]}"
  elif [ "$mod" = "+0" ]; then
    IFS=','; echo "🎲 ${num}d${sides} → [${rolls[*]}] = $total"
  else
    IFS=','; echo "🎲 ${num}d${sides}${mod} → [${rolls[*]}] ${mod} = $total"
  fi
else
  echo "无法解析: $expr"
  exit 1
fi
