#! /usr/bin/gawk -f

# invoke git-restate(1) in each REPO project directory
# On any failure the final exit status will be non-null.
# on STDOUT the messages.
#  on success, git-stash pop if requested.

# input is the horizont file of this format:
# dir TAB  ref:  TAB stash-sha
# ...
BEGIN {FS="	";
        exit_code=0;
        cmd="" #echo
}



{
        printf("dir = %s\n", $1);
        printf("ref = %s\n", $2);
        head = $2
        gsub(/^ref: /,"", head);

        printf("branch = %s\n", head);

        result=system(sprintf("%s git-restate %s \"%s\"", cmd, $1, head));
        if (result != 0) {
                printf "**** git-restate failed in %s: %d\n", $1, result;
                exit_code=1;
                # Give up:
                next
	} else if (NF == 3) {
                printf("stash pop %s\n", $3)
                result=system(sprintf("%s cd %s; %s git stash pop", cmd, $1, cmd));
        }
}

# /^(.*)	(.*)	(.+)$/  {
#     # todo: check $3
#         result=system(sprintf("%s cd %s; %s git stash pop", cmd, $1, cmd));
#     if (result != 0) { printf "**** stash POP failed %d\n", result; exit_code=1};
# }


END { exit exit_code}
