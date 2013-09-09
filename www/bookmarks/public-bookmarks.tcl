# /www/bookmarks/public-bookmarks.tcl

ad_page_contract {
    show other people's bookmarks
    @author dh@arsdigita.com and aure@arsdigita.com
    @creation-date June 1999  
    @cvs-id public-bookmarks.tcl,v 3.2.2.6 2000/09/22 01:37:03 kevin Exp
} {} 

set title "Public Bookmarks"

set whole_page "
[ad_header $title ]

<h2> $title </h2>

[ad_context_bar_ws_or_index [list "index.tcl" [ad_parameter SystemName bm]] $title]

<hr>"

set user_count 0
set user_list ""

db_foreach sql_query {
    select  first_names, 
            last_name, 
            owner_id as viewed_user_id, 
            count(bookmark_id) as number_of_bookmarks
    from    users, bm_list
    where   user_id = owner_id
    and     hidden_p = 'f'
    group by first_names, 
             last_name, 
             owner_id
    order by number_of_bookmarks desc
} {
    incr user_count            
    append user_list "<li><a href=public-bookmarks-for-one-user?[export_url_vars viewed_user_id] >$first_names $last_name</a> ($number_of_bookmarks)\n"
}

if { $user_count > 0 } {
    append whole_page "

Look at the most popular bookmarks:  <a href=\"most-popular-public\">summarized by URL</a>

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



doc_return  200 text/html $whole_page

