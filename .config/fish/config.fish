# 提示词设置
function fish_greeting
    # 缓存文件存放位置
    set cache_file ~/.cache/fish_daily_quote.txt
    set today (date "+%Y-%m-%d")

    # 如果缓存文件不存在，或者缓存日期不是今天，就重新获取
    if not test -e $cache_file; or test (head -n1 $cache_file) != $today
        # 拉取每日一言（ZenQuotes.io）
        set json (curl -s https://zenquotes.io/api/today)

        set quote (echo $json | jq -r '.[0].q')
        set author (echo $json | jq -r '.[0].a')

        echo $today >$cache_file
        printf "%s\n%s\n" "$quote" "$author" >>$cache_file
    end

    # 读取缓存
    set quote (sed -n '2p' $cache_file)
    set author (sed -n '3p' $cache_file)

    # 计算长度
    set len_quote (string length -- $quote)
    set len_author (string length -- $author)

    set_color magenta
    printf "┌\n"
    set_color blue
    printf "%*s%s\n" (math 2) "" "$quote"
    set_color brblack
    printf "%*s— %s\n" (math $len_quote - $len_author) "" "$author"
    set_color magenta
    printf "%*s┘\n" (math $len_quote + 3) ""
    set_color blue
    echo "Hello bdbd!"
    set_color normal
end

set -e MANPAGER
set -e MANPAGEG
if status is-interactive
    batman --export-env | source
    # 交互模式下的别名
    alias ex="exit"
    alias cl="clear"
    alias vi="nvim"
    alias nv="neovide"
    alias ls="eza --color=always --icons=always --git --group-directories-first"
    alias la="eza --color=always --icons=always --git --group-directories-first -lha"
    alias tm="tmux"
    alias tmm="tmux new -A -s main"
    alias archwiki="xdg-open /usr/share/doc/arch-wiki-zh-cn/html/zh-cn/首页.html"
    alias lg="lazygit"
    alias ff="fastfetch"
    alias oc="opencode"
    # if type -q swallow
    #   alias code="swallow code --wait"
    #   alias nv="swallow neovide"
    # end
    # yazi 目录跳转
    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end
    # 初始化 zoxide
    if type -q zoxide
        zoxide init --cmd cd fish | source
    end

    # 优化 thefuck 速度
    if type -q thefuck
        function fuck --wraps='thefuck' --description 'Correct previous command'
            thefuck $history[1] | source
        end
    end
    if type -q starship
        starship init fish | source
    end
end

set -Ux EDITOR nvim

bind \co accept-autosuggestion

# add the -g flag to show the group belonged
function ll --wraps=ls --description 'List contents of directory using long format'
    ls -lhg $argv
end

set -Ux LITELOADERQQNT_PROFILE ~/.config/LiteloaderQQNT/
