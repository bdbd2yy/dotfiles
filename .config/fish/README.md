# Fish 使用教程

这份文档记录当前仓库里的 Fish 配置和已安装 Fisher 插件，重点是日常用法和维护方式。

## 配置入口

主配置文件：

```fish
~/.config/fish/config.fish
```

插件清单：

```fish
~/.config/fish/fish_plugins
```

当前 Fisher 插件：

```text
jorgebucaran/fisher
jorgebucaran/nvm.fish
patrickf1/fzf.fish
meaningful-ooo/sponge
franciscolourenco/done
jorgebucaran/autopair.fish
```

## 启动行为

打开交互式 Fish 时会执行 `fish_greeting`：

- 读取 `~/.cache/fish_daily_quote.txt` 中缓存的每日一句。
- 如果缓存不是今天，并且 `curl`、`jq` 可用，会从 ZenQuotes 拉取当天 quote。
- 网络请求有短超时限制，避免终端启动被长时间卡住。
- 显示本次 Fish 配置启动耗时，例如 `Fish startup: 120ms`。
- 最后显示 `Hello bdbd!`。

非交互式 Fish 会跳过交互相关初始化，避免影响脚本执行。

## 常用缩写

Fish 的 `abbr` 不是普通 alias。输入缩写后按空格或回车，它会展开成完整命令，展开后的命令会进入 history。

| 缩写 | 展开后 |
| --- | --- |
| `ex` | `exit` |
| `cl` | `claude` |
| `clr` | `claude --resume` |
| `clc` | `claude --continue` |
| `cld` | `claude --dangerously-skip-permissions` |
| `vi` | `nvim` |
| `nv` | `neovide` |
| `ls` | `eza --color=always --icons=always --git --group-directories-first` |
| `la` | `eza --color=always --icons=always --git --group-directories-first -lha` |
| `tm` | `tmux` |
| `tmm` | `tmux new -A -s main` |
| `archwiki` | 打开本地 Arch Wiki 中文页面 |
| `lg` | `lazygit` |
| `ff` | `fastfetch` |
| `oc` | `opencode` |

项目跳转缩写：

| 缩写 | 行为 |
| --- | --- |
| `dev` | 从 `$HOME/Programming/dev/` 下一级目录中用 `fzf` 选择，进入后打开 `nvim .` |
| `learn` | 从 `$HOME/Programming/learn/` 下两级目录中用 `fzf` 选择，进入后打开 `nvim .` |

示例：

```fish
dev
learn
tmm
lg
```

## fzf 集成

当前通过 `patrickf1/fzf.fish` 集成 `fzf`，不用手动执行 `fzf` 再复制结果。

常用默认快捷键：

| 快捷键 | 功能 |
| --- | --- |
| `Ctrl+R` | 搜索 Fish 命令历史 |
| `Ctrl+Alt+F` | 搜索当前目录文件和目录 |
| `Ctrl+Alt+S` | 搜索 Git status 中的文件 |
| `Ctrl+Alt+L` | 搜索 Git log，并插入 commit hash |
| `Ctrl+Alt+P` | 搜索进程，并插入 PID |
| `Ctrl+V` | 搜索 Fish 变量 |

用法要点：

- 在命令行中间触发搜索时，当前光标所在 token 会作为初始查询。
- 搜索结果会直接插入当前命令行，不会立即执行。
- 多选时通常用 `Tab` 标记多个结果。
- 文件、Git 和进程搜索带 preview，更适合替代临时 `find`、`git log | fzf`、`ps | fzf`。

如果要查看或修改快捷键：

```fish
fzf_configure_bindings --help
```

## 目录跳转

当前配置启用了 `zoxide`：

```fish
zoxide init --cmd cd fish | source
```

这会让 `cd` 变成基于访问频率和最近使用记录的智能跳转。

示例：

```fish
cd dotfiles
cd nvim
cd waybar
```

第一次访问某个目录时仍然需要正常路径，之后可以用模糊关键词跳转。

## Yazi 目录返回

配置里定义了 `y` 函数：

```fish
y
```

它会启动 `yazi`。在 Yazi 里切换目录后退出，Fish 会自动 `cd` 到 Yazi 最后所在目录。

可以带参数：

```fish
y .
y ~/Downloads
```

## Node 版本管理

当前通过 `jorgebucaran/nvm.fish` 管理 Node.js 版本。

常用命令：

```fish
nvm install lts
nvm install latest
nvm install 20
nvm use 20
nvm list
nvm list-remote
```

项目内支持 `.nvmrc` 和 `.node-version`：

```fish
node --version > .nvmrc
nvm install
nvm use
```

如果要设置默认版本：

```fish
set --universal nvm_default_version lts
```

## History 清理

当前通过 `meaningful-ooo/sponge` 自动清理 history。

默认行为：

- 失败命令通常不会长期污染 history。
- 最近 2 条命令仍会保留，方便立刻修正 typo。
- 不会追溯清理旧 history。

如果安装后想清一次旧历史：

```fish
history clear
```

谨慎使用这个命令，因为它会清空已有 Fish history。

## 长命令完成通知

当前通过 `franciscolourenco/done` 在长命令结束后发通知。

默认超过 5 秒的命令可能触发通知。可以调整阈值，例如改成 10 秒：

```fish
set -U __done_min_cmd_duration 10000
```

如果某些命令不想通知，可以配置排除规则：

```fish
set -U --append __done_exclude '^nvim'
set -U --append __done_exclude '^yazi'
```

在 Linux 桌面环境下通常依赖 `notify-send`。

## 自动补全成对符号

当前通过 `jorgebucaran/autopair.fish` 自动补全成对符号。

典型行为：

- 输入 `"` 会补成 `""`，光标停在中间。
- 输入 `'`、`(`、`[`、`{` 等会自动补全对应闭合符号。
- 在已有闭合符号前继续输入对应符号时，会跳过闭合符号。

这对写带引号参数、JSON 片段、复杂 shell 命令比较有用。

## Prompt 和命令增强

如果系统里有这些命令，当前配置会自动启用：

| 命令 | 用途 |
| --- | --- |
| `starship` | Shell prompt |
| `batman` | man page pager |
| `thefuck` | 修正上一条命令，使用 `fuck` |
| `zoxide` | 智能 `cd` |

`thefuck` 的用法：

```fish
git statsu
fuck
```

`fuck` 会读取上一条命令并生成修正命令，然后交给 Fish 执行。

## 自定义函数

当前定义了 `ll`：

```fish
ll
ll ~/.config
```

实际执行：

```fish
ls -lhg
```

注意这里的 `ls` 在交互式环境里是缩写，输入 `ll` 调用函数时，函数内部仍按 Fish 的命令解析执行。

## 路径顺序

配置会把 `/opt/anaconda/bin` 放到 `/usr/bin` 后面，避免 Anaconda 的 shim 抢在系统命令前面。

如果排查命令来源：

```fish
type python
type pip
type node
```

## 插件维护

查看已安装插件：

```fish
fisher list
```

安装插件：

```fish
fisher install owner/repo
```

更新所有插件：

```fish
fisher update
```

更新单个插件：

```fish
fisher update PatrickF1/fzf.fish
```

移除插件：

```fish
fisher remove owner/repo
```

Fisher 会维护 `~/.config/fish/fish_plugins`。这份文件应该跟随 dotfiles 提交，方便新机器恢复同样插件。

## 配置检查

修改 Fish 配置后，先跑语法检查：

```fish
fish -n ~/.config/fish/config.fish
```

重新打开一个终端，确认：

- greeting 正常显示。
- `Fish startup: ...ms` 正常显示。
- `Ctrl+R` 能打开 fzf history。
- `cd <关键词>` 能使用 zoxide 跳转。
- `nvm list` 正常工作。

