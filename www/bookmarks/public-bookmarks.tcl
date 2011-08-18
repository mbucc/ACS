# $Id: public-bookmarks.tcl,v 3.0 2000/02/06 03:35:40 ron Exp $
# public-bookmarks.tcl
#
# show other people's bookmarks
#
# by dh@arsdigita.com and aure@arsdigita.com
#
# modified by philg@mit.edu on November 7, 1999
# to include a link to the most popular, release the 
# database handle, etc.

set title "Public Bookmarks"

set db [ns_db gethandle]


set whole_page "
[ad_header $title ]

<h2> $title </h2>

[ad_context_bar_ws_or_index [list "index.tcl" [ad_parameter SystemName bm]] $title]

<hr>"

set sql_query "
select  first_names, last_name, owner_id as viewed_user_id, count(bookmark_id) as number_of_bookmarks
from    users, bm_list
where   user_id=owner_id
and     hidden_p='f'
group by first_names, last_name, owner_id
order by number_of_bookmarks desc"

set selection [ns_db select $db $sql_query]
set user_count 0
set user_list ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr user_count            
    append user_list "<li><a href=public-bookmarks-for-one-user.tcl?[export_url_vars viewed_user_id] >$first_names $last_name</a> ($number_of_bookmarks)\n"
}

if { $user_count > 0 } {
    append whole_page "

Look at the most popular bookmarks:  <a href=\"most-popular-public.tcl\">summarized by URL</a>

<P>

or

<p>

Choose a user whose public bookmarks you would like to view:

<ul>
$user_list
</ul>
"
} else {
    append whole_page "There are no users in this system with public bookmarks"
}

append whole_page [bm_footer]

ns_db releasehandle $db

ns_return 200 text/html $whole_page




