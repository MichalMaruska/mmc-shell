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

# new:
stash_commit=
mmc_stash_if_non_clean()
{
    local message=$1
    stash_commit=$(git stash create $message)
    # is it HEAD ?
    if [[ -n $stash_commit ]]; then
        # this message goes into .git/logs/refs/stash
        # 'stash for git-ff'
        cecho yellow "stashed for you in $stash_commit"
        git stash store -m $message $stash_commit
    fi
}

mmc_unstash_if_stashed()
{
    if [[ -n "$stash_commit" ]]
    then
        cecho yellow "unstashing now."
        git stash pop --quiet
    fi
}



# is the $1 a valid ref to remote branch?
is_git_remote_branch()
{
    git rev-parse remotes/$1 2>/dev/null
}

# is it a name of a remote?
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


# Given 2 commits as parameters ... look at the lattice
# return 1 if A < B
# 0 if  A=B
# 1 less
# 2 more
# 3  incomparable
# 4 error?

#  Uses: $verbose
compare_commits()
{
    # the sha?
    # $(git rev-parse $1)
    # local
    readonly first=$(git log $1 --max-count=1 --format="%H")
    readonly second=$(git log $2 --max-count=1 --format="%H")

    if [[ -z "$first" || -z "$second" ]]; then
        if [[ $verbose = n ]]; then echo "$first $second" >&2;fi
        return 4
    fi
    if [[ $first = $second ]]; then
        return 0;
    fi

    # `merge-base' is the key:
    readonly common=$(git merge-base $first $second)
    if [ $? != 0 ]; then
        if [[ $verbose != n ]]; then echo "no common merge-base">&2;fi
        return 4;
    fi

    if [[ $common = $second ]]; then
        return 1;
    elif [[ $common = $first ]]; then
        return 2;
        # -1 is nonsense if ever a standalone,
        # but it got delivered as -1 as function!
    else
        return 3
    fi
}
