#!/bin/zsh -f
# to be sourced!

function get_local_path()
{
    local TOP=$1
    local local_path=$(pwd)
    local_path=${local_path#$TOP}
    echo $local_path
}
