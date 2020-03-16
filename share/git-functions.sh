#!/bin/zsh -f
# to be sourced!

function get_remote_path()
{
    # Strip $HOME
    local local_path=$(pwd)
    local_path=${local_path#$HOME}

    local remote_home=/home/michal

    remote_path=$remote_home$local_path
    echo $remote_path
}

# set GIT_URL
guess_twin()
{
    case $(hostname) in
        e6440 | inspiron)
            GIT_REMOTE_NAME=optiplex
            ;;
        optiplex | optiplex-maruska)
            GIT_REMOTE_NAME=e6440
            ;;
        *)
    esac

    GIT_URL="michal@$GIT_REMOTE_NAME:$(get_remote_path)"
}

# sets GIT_REMOTE_NAME and GIT_URL
# the `favorite' one:
set_remote_name()
{
    readonly remotes=($(git remote))

    # need a dictionary of these:

    # host e6440
    # members of e6440_siblings=()
    # if [[ ${e6440_siblings[(i)$hostname]} -le ${#e6440_siblings} ]]

    if [[ ${#remotes} = 1 ]]
    then
        GIT_REMOTE_NAME=${remotes[1]}
    else
        e6440_siblings=(optiplex-maruska )
        optiplex_siblings=(lat7280 e7240 inspiron e6440)
        if [[ -n ${remotes[(re)e6440]-} &&
                  ${e6440_siblings[(i)$hostname]} -le ${#e6440_siblings} ]]
        then
            # todo: check it exists:
            : ${GIT_REMOTE_NAME=e6440}
        elif [[ -n ${remotes[(re)optiplex]-}
                && ${optiplex_siblings[(i)$hostname]} -le ${#optiplex_siblings} ]]
        then
            : ${GIT_REMOTE_NAME:=optiplex}
        else
            die "$0 cannot decide for a favorite remote"
        fi
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
