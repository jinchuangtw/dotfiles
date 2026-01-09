if status is-interactive
    # Commands to run in interactive sessions can go here
end

fish_config theme choose "Dracula Official"

# ------------------------------------------------------------
# PATH manage in /usr/local
fish_add_path -g /usr/local/nvim-linux64/bin
fish_add_path -g /usr/local/.cargo/bin
fish_add_path -g /usr/local/cuda-11.3/bin 
fish_add_path -g /usr/local/MATLAB/R2022a/bin
fish_add_path -g /usr/local/texlive/2024/bin/x86_64-linux
fish_add_path -g /usr/local/Telegram

# ------------------------------------------------------------
# alias settings
alias ls='logo-ls'
alias la='logo-ls -A'
alias ll='logo-ls -al'

alias vim='nvim'
alias vi='nvim'
alias v='nvim'

alias cm='mkdir build && cd build && cmake ..'
alias recm='cd .. && rm -rf build && mkdir build && cd build && cmake ..'

alias iec='sudo tailscale up --exit-node="iec-nas.taild6cb20.ts.net"'
alias iecc='sudo tailscale set --exit-node='

# ------------------------------------------------------------
# ros settings
source /opt/ros/noetic/share/rosbash/rosfish
bass source ~/Development/catkin_ws/devel/setup.bash

# ------------------------------------------------------------
# pyenv init
set -gx PYENV_ROOT $HOME/.pyenv
if test -d $PYENV_ROOT/bin
    fish_add_path -g $PYENV_ROOT/bin
end
if type -q pyenv
    pyenv init - fish | source
end

# ------------------------------------------------------------
# conda init
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/jinchuangtw/miniconda3/bin/conda
    eval /home/jinchuangtw/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/home/jinchuangtw/miniconda3/etc/fish/conf.d/conda.fish"
        source "/home/jinchuangtw/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/jinchuangtw/miniconda3/bin" $PATH
    end
end

if test -d /home/jinchuangtw/miniconda3/bin
    fish_add_path -m /home/jinchuangtw/miniconda3/bin
end

# -----------------------------------------------------------
