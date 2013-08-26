#! /usr/bin/awk -f


BEGIN {
        getline
        current=$0
        count=1
}

{
        if ($0 == current) {
                count++;
        } else {
                printf "%s\t%s\n", count ,current
                # print current, count
                current=$1
                count=1;
        }
}


END {
        printf "%s\t%s\n", count ,current
}
