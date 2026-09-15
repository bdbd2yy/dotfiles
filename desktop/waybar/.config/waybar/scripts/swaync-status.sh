#!/usr/bin/env bash

swaync-client -swb | jq --unbuffered --compact-output '
  (.alt // "none") as $state
  | (.text | tonumber? // 0) as $count
  | if $state | contains("inhibited") then "应用抑制"
    elif $state | startswith("dnd") then "勿扰模式"
    else "正常"
    end as $mode
  | .tooltip = "通知：\($count) 条\n状态：\($mode)\n左键：打开通知中心\n右键：切换勿扰模式"
'
