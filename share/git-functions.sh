#!/bin/zsh -f
# to be sourced!

# sets GIT_REMOTE_NAME and GIT_URL
# the `favorite' one:
set_remote_name()
{
    readonly remotes=($(git remote))

    if [[ ${#remotes} = 1 ]]
    then
        GIT_REMOTE_NAME=${remotes[1]}
    elif [[ $(hostname) = e6440 && -n ${remotes[(re)optiplex]} ]]
    then
        # todo: check it exists:
        : ${GIT_REMOTE_NAME:=optiplex}
    elif [[ $(hostname) = "optiplex-maruska" &&  -n ${remotes[(re)e6440]} ]]
    then
        : ${GIT_REMOTE_NAME=e6440}
    else
        die "cannot decide for a favorite remote"
    fi

    GIT_URL=$(git remote get-url $GIT_REMOTE_NAME)
    return
}

# # REMOTE=FETCH_HEAD


function get_local_path()
{
    local TOP=$1
    local local_path=$(pwd)
    local_path=${local_path#$TOP}
    echo $local_path
}

function git-branch-exists()
{
    git show-ref refs/heads/$1 >/dev/null;
}

function git_ref_exists()
{
    git show-ref refs/$1 >/dev/null;
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

git_dir()
{
    ## --git-common-dir would be global to all worktrees.
    git rev-parse --git-dir
}

# fixme: protect this:
GIT_STASHED=no
## possibly stash:
# sets the variable STASHED
stash_if_non_clean()
{
    # fixme: some variable is used-before-defined, in upstream code.
    # this is run after processing the command line args. Otherwise -h would be
    # handled by it
    set +u
    . /usr/lib/git-core/git-sh-setup
    # git rev-parse --is-inside-work-tree
    GIT_DIR=$(git_dir)
    set -u

    # todo:
    # octopus can leave half work, so yes, I prefer:
    if ! ( require_clean_work_tree $1 "$(gettext "Please commit or stash them.")" )
    then
        # todo: orange:
        cecho yellow "stashing for you..."
        git stash push
        GIT_STASHED=yes
    fi
}


unstash_if_stashed()
{
    if [ "$GIT_STASHED" = "yes" ]
    then
        cecho yellow "unstashing now."
        # eval $cmd
        git stash pop --quiet
    fi
}



is_git_remote_branch()
{
    git rev-parse remotes/$1 2>/dev/null
}

is_git_remote()
{
    git remote get-url $1 > /dev/null
    # git remote | grep -F $1
}

# Given a filename & `commitish'.
cat_git_file_from_commit()
{
    readonly commit=$1
    readonly FILENAME=$2

    readonly tree="$commit^{tree}"

    # set -x
    # tree:
    if [[ "tree" != $(git cat-file -t "$tree") ]]
    then
        die "not a tree"
    fi

    local line=$(git cat-file -p $tree |grep $FILENAME)


    # echo $line
    if [[ $line -regex-match "[[:digit:]]{6} blob ([[:xdigit:]]+)	hierarchy" ]]
    then
        # MATCH the whole match, match submatches!
        # print -l $MATCH X $match[1]
        git cat-file -p $match[1]
    else
        exit 1
    fi
}
