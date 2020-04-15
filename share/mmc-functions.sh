#!/bin/zsh -feu

check_getopt()
{
    if getopt -T; then # should test (( $? = -4 ))
        echo "incompatible  getopt(1) installed. Abort"
        exit -1
    fi
}

traced_exec()
{
    x=$options[xtrace]
    options[xtrace]=on
    eval $@
    options[xtrace]=$x
}

local_cecho()
{
    color=$1
    shift
    echo $fg[$color] $@ $reset_color
}

die()
{
    colors
    local_cecho blue "ERROR:" $@ >&2
    exit -1
}

INFO()
{
    # green
    local_cecho yellow $@
}

pause()
{
    print "$1"
    print "pause: Enter to continue"
    read cont
}

LOG_STEP()
{
    local_cecho cyan $@
}

dump_stack()
{
    for ((i=${#zsh_eval_context}; i > 0; i--))
    do
        echo ${zsh_eval_context[i]}
    done
}

# the user can autoload it by calling "colors"
autoload -Uz colors

if false;
then
load_colors()
{
    source /usr/share/zsh/functions/Misc/colors

    # color
    # reset_color bold_color
    # fg fg_bold fg_no_bold
    # bg ....
}
fi
