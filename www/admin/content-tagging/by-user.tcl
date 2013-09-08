# File: /www/admin/comment-tagging/by-user.tcl
ad_page_contract {
    Displays naughtiness by user
    @param none
    @author unknown
    @cvs-id by-user.tcl,v 3.1.6.4 2000/09/22 01:34:35 kevin Exp
} {
}


set title "Naughtiness by user"

append page_content "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Content Tagging Package"] $title]

<hr>
 
<ul>
"


db_foreach select_offensive_text "select offensive_text, naughty_events.table_name, the_key, creation_date, user_id, first_names, last_name, url_stub
from naughty_events, users, naughty_table_to_url_map
where creation_user = users.user_id
and naughty_events.table_name=naughty_table_to_url_map.table_name(+)
order by creation_date, upper(last_name), upper(first_names)" {
    append page_content "<li><a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a> \n
    <br>$offensive_text <br> " 
    
    if {[empty_string_p $url_stub]} {
	append page_content "<b>Date:</b> [util_AnsiDatetoPrettyDate $creation_date]<p>" 
    } else {
	append page_content "<b>Date:</b> [util_AnsiDatetoPrettyDate $creation_date]<br>
	<a href=\"$url_stub[ns_urlencode $the_key]\">Edit</a><p>" 
    }
}
    


 
append page_content "
</ul>

[ad_admin_footer]
"



doc_return  200 text/html $page_content






