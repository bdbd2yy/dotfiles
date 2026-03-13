# 提示词设置
function fish_greeting
    # 缓存文件存放位置
    set -l cache_file ~/.cache/fish_daily_quote.txt
    set -l today (date "+%Y-%m-%d")
    set -l quote ""
    set -l author ""

    # 先读取缓存，确保网络异常时也不会阻塞 shell 启动
    if test -e $cache_file
        set quote (sed -n '2p' $cache_file)
        set author (sed -n '3p' $cache_file)
    end

    # 如果缓存文件不存在，或者缓存日期不是今天，就尝试重新获取
    if type -q curl; and type -q jq
        if not test -e $cache_file; or test (head -n1 $cache_file) != $today
            # 拉取每日一言（ZenQuotes.io），限制超时避免终端卡在启动阶段
            set -l json (curl -fsS --connect-timeout 2 --max-time 3 https://zenquotes.io/api/today 2>/dev/null)

            if test $status -eq 0; and test -n "$json"
                set -l new_quote (printf "%s" "$json" | jq -r '.[0].q // empty' 2>/dev/null)
                set -l new_author (printf "%s" "$json" | jq -r '.[0].a // empty' 2>/dev/null)

                if test -n "$new_quote"; and test -n "$new_author"
                    mkdir -p (dirname $cache_file)
                    echo $today >$cache_file
                    printf "%s\n%s\n" "$new_quote" "$new_author" >>$cache_file
                    set quote $new_quote
                    set author $new_author
                end
            end
        end
    end

    if test -n "$quote"; and test -n "$author"
        # 计算长度
        set -l len_quote (string length -- $quote)
        set -l len_author (string length -- $author)

        set_color magenta
        printf "┌\n"
        set_color blue
        printf "%*s%s\n" (math 2) "" "$quote"
        set_color brblack
        printf "%*s— %s\n" (math $len_quote - $len_author) "" "$author"
        set_color magenta
        printf "%*s┘\n" (math $len_quote + 3) ""
    end

    set_color blue
    echo "Hello bdbd!"
    set_color normal
end

set -e MANPAGER
set -e MANPAGEG
if status is-interactive
    # 交互模式下的缩写
    abbr --add ex exit
    abbr --add cl clear
    abbr --add vi nvim
    abbr --add nv neovide
    abbr --add ls "eza --color=always --icons=always --git --group-directories-first"
    abbr --add la "eza --color=always --icons=always --git --group-directories-first -lha"
    abbr --add tm tmux
    abbr --add tmm "tmux new -A -s main"
    abbr --add archwiki "xdg-open /usr/share/doc/arch-wiki-zh-cn/html/zh-cn/首页.html"
    abbr --add lg lazygit
    abbr --add ff fastfetch
    abbr --add oc opencode
    # if type -q swallow
    #   abbr --add code "swallow code --wait"
    #   abbr --add nv "swallow neovide"
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

    if type -q batman 
        batman --export-env | source
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
