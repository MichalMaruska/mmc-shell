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
    cecho blue $@ >&2
    exit 1
}

INFO()
{
    cecho green $@
}
