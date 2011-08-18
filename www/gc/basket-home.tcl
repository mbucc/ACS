# $Id: basket-home.tcl,v 3.1 2000/03/10 23:58:21 curtisg Exp $
set db [gc_db_gethandle]

set headers [ns_conn headers]
set cookie [ns_set get $headers Cookie]
if { $cookie == "" || 
     ( $cookie != "" && ![regexp {HearstClassifiedBasketEmail=([^;]*)$} $cookie match just_the_cookie] ) } {
    # there was no cookie header or there was, but it didn't match for us
    ns_return 200 text/html "couldn't find a cookie header; this feature only works with cookie-compatible browsers (mostly Netscape)"
    return
} else {
    # we get the last one if there are N
    regexp {HearstClassifiedBasketEmail=([^;]*)$} $cookie match just_the_cookie
    set key $just_the_cookie
}

append html "<html>
<head>
<title>Basket for $key</title>
</head>
<body bgcolor=#ffffff text=#000000>
<h2>Basket for $key</h2>


<p>

"
#set selection [ns_db select $db "select distinct a.ad_id,headline,print_text,web_text
#from user_picks up, ads a
#where up.ad_id = a.ad_id
#and up.email = '[DoubleApos $key]'"]

# would have been nice to "order by up.tmin desc" but that means we
# end up with duplicate rows because Illustra requires order by 
# columns to be in the SELECT list

# here's a hairy fix with GROUP BY out the wazoo...

set selection [ns_db select $db "select a.ad_id,headline,print_text,web_text,
max(up.tmin) as last_marked_time
from user_picks up, ads a
where up.ad_id = a.ad_id
and up.email = '[DoubleApos $key]'
group by a.ad_id,headline,print_text,web_text
order by 5 desc"]

while {[ns_db getrow $db $selection]} {

    set_variables_after_query
    if { $web_text == "" } {
	set full_text "<b>$headline</b> $print_text"
    } else {
	set full_text $web_text
    }
    append html "<a href=\"remove-from-basket.tcl?ad_id=$ad_id\">
<img src=add.gif width=32 height=32 hspace=5 vspace=0 align=right></a>
$full_text
<hr width=300><br clear=right>\n"

}

append html "[gc_footer [gc_system_owner]]
"

ns_return 200 text/html $html
