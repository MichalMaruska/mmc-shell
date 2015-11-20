#! /usr/bin/gawk -f

BEGIN {FS="	";}

# I need TABS as delimiters
# the input is:
# dir TAB sha TAB ref: .... TAB sha-of-stash
# sort-of a grep
/ref: ([^	]*)/ {
        printf "%s\t%s",$1, $3;
        if ($4 != "") {printf "\t%s",$4;};

        printf "\n";
}

# This is not correct: sometimes it's the SHA1 not dirname!
# {getline; dir=$0}

