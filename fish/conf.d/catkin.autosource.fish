function catkinSource --on-variable PWD
    status --is-command-substitution; and return
    if test -e ".catkin_workspace"; or test -e ".catkin_tools"
        bass source devel/setup.bash
        fish_add_path -m $PYENV_ROOT/bin
        fish_add_path -m $PYENV_ROOT/shims
        pyenv rehash
        echo "Configured the folder as a workspace"
    end
end
