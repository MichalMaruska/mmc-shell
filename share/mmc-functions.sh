#!/bin/zsh -feu

check_getopt()
{
    if getopt -T; then # should test (( $? = -4 ))
        echo "incompatible  getopt(1) installed. Abort"
        exit -1
    fi
}

die()
{
    cecho blue "ERROR:" $@ >&2
    exit -1
}


INFO()
{
    cecho green $@
}

LOG_STEP()
{
    cecho cyan $@
}


dump_stack()
{
    for ((i=${#zsh_eval_context}; i > 0; i--))
    do
        echo ${zsh_eval_context[i]}
    done
}

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
