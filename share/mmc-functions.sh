#!/bin/zsh -feu

check_getopt()
{
    if getopt -T; then # should test (( $? = -4 ))
        echo "incompatible  getopt(1) installed. Abort"
        exit -1
    fi
}

optional_traced_exec()
{
    if [[ $debug = yes ]]
    then
        traced_exec $@
    else
        eval $@
    fi
}

traced_exec()
{
    local x=$options[xtrace]
    options[xtrace]=on
    eval $@
    local last_status=$?
    options[xtrace]=$x
    return $last_status
}

local_cecho()
{
    color=$1
    shift
    echo "$fg[$color]$@$reset_color"
}

die()
{
    set +x
    colors
    local_cecho blue "ERROR:" $@ >&2
    exit -1
}

info()
{
    # green
    local_cecho yellow $@
}
# INFO=info

warn()
{
    local_cecho red $@
}

# bash has read -p
pause()
{
    print "$1"
    local cont
    read "cont?Enter to continue ..."
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
