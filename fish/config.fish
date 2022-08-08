if status is-interactive
    # Commands to run in interactive sessions can go here
end


# pyenv init
if command -v pyenv 1>/dev/null 2>&1
  pyenv init --path | source
end

source ~/.local/share/icons-in-terminal/icons.fish
alias ls='logo-ls'
alias la='logo-ls -A'
alias ll='logo-ls -al'
