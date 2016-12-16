#!/bin/zsh -f
# to be sourced!

# sets GIT_REMOTE_NAME and GIT_URL
set_remote_name()
{
    if [ $(hostname) = e6440 ]; then
        : ${GIT_REMOTE_NAME:=optiplex}
        : ${GIT_URL:=michal@optiplex}
    else
        : ${GIT_REMOTE_NAME=e6440}
        : ${GIT_URL=michal@e6440}
    fi
}

function get_local_path()
{
    local TOP=$1
    local local_path=$(pwd)
    local_path=${local_path#$TOP}
    echo $local_path
}

function git_ref_exists()
{
    [ -e .git/refs/$1 ]
}
