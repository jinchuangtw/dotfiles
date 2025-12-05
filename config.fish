if status is-interactive
    # Commands to run in interactive sessions can go here
end

fish_config theme choose "Dracula Official"

# pyenv init
export PYENV_ROOT="$HOME/.pyenv"
if command -v pyenv 1>/dev/null 2>&1
  pyenv init --path | source
  # pyenv init - | source
  # pyenv virtualenv-init - | source
end

# ros settings
source /opt/ros/noetic/share/rosbash/rosfish
bass source ~/Development/catkin_ws/devel/setup.bash

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
alias iecc='sudo tailscale down'
