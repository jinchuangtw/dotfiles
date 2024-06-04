if status is-interactive
    # Commands to run in interactive sessions can go here
end

fish_config theme choose "Dracula Official"

# pyenv init
export PYENV_ROOT="$HOME/.pyenv"
if command -v pyenv 1>/dev/null 2>&1
  pyenv init --path | source
end

# ros settings
# bass source /opt/ros/noetic/setup.bash
# bass source ~/Development/catkin_ws/devel/setup.bash

# alias settings
alias ls='logo-ls'
alias la='logo-ls -A'
alias ll='logo-ls -al'

alias vim='nvim'
alias vi='nvim'
alias v='nvim'
