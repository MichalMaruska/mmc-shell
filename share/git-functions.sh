#!/bin/zsh -f
# to be sourced!

# sets GIT_REMOTE_NAME and GIT_URL
set_remote_name()
{
    if [ $(hostname) = e6440 ]; then
        : ${GIT_REMOTE_NAME:=optiplex}
        : ${GIT_URL:=michal@optiplex}
    else # [ $(hostname) = "optiplex-maruska" ];
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

# please use the one in ~/repo/git-hierarchy/share/functions.sh
# return the branch checked-out. Error if in "detached HEAD" state.
function current_branch_name()
{
    local head
    head=$(git rev-parse --symbolic-full-name HEAD)
    head=${head##refs/heads/}
    if [ $head = HEAD ]; then
        cecho red "currently not on a branch" >&2
        exit 1;
    fi

    echo "$head"
}
