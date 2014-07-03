#! /usr/bin/gawk -f

BEGIN {exit_code=0;
cmd=""
# echo
}

# {print $1, $2, $3;}
# \t?(.*)?$

/^.*	.*/  {
    print "running";
    result=system(sprintf("%s git-restate %s %s", cmd, $1, $2));
    if (result != 0) {
	    printf "**** git-restate failed in %s: %d\n", $1, result;
	    exit_code=1;
	    # Give up:
	    next
	};
}

/^(.*)	(.*)	(.+)$/  {
    # todo: check $3
    result=system(sprintf("cd %s; %s git stash pop", $1, cmd));
    if (result != 0) { printf "**** stash POP failed %d\n", result; exit_code=1};
}


END { exit exit_code}
