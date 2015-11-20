#! /usr/bin/gawk -f

BEGIN {FS="	";
        getline;dir=$0}

# I need TABS as delimiters
# the input is:
# sha TAB ref: .... TAB sha-of-stash
/ref: ([^	]*)/ {
        printf "%s\t%s", dir, $2;
        if ($3 != "") {printf "\t%s",$3;};

        printf "\n";
}

# This is not correct: sometimes it's the SHA1 not dirname!
{getline; dir=$0}

