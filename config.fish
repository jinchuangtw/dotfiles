if status is-interactive
    # Commands to run in interactive sessions can go here
end

fish_config theme choose "Dracula Official"

# pyenv init
# if command -v pyenv 1>/dev/null 2>&1
#   pyenv init --path | source
# end

# activate cool icons
source ~/.local/share/icons-in-terminal/icons.fish

# ros settings
bass source /opt/ros/noetic/setup.bash
bass source ~/Development/catkin_ws/devel/setup.bash

# alias settings
alias ls='logo-ls'
alias la='logo-ls -A'
alias ll='logo-ls -al'

alias vim='nvim'
alias vi='nvim'
alias v='nvim'
