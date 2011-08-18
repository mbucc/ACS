

ReturnHeaders

set one "a one and a"
set two [list "two"]
set three ""

set thelist [list $one $two $three]

set n 1
foreach item $thelist {
    ns_write "<br>$n: $item"
    incr n
} 


ns_write "<br>$thelist"