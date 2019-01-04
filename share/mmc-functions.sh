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
