# $Id: by-user.tcl,v 3.0 2000/02/06 03:15:26 ron Exp $
ReturnHeaders

set title "Naughtiness by user"

ns_write "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Content Tagging Package"] $title]

<hr>
 
<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select offensive_text, naughty_events.table_name, the_key, creation_date, user_id, first_names, last_name, url_stub
from naughty_events, users, naughty_table_to_url_map
where creation_user = users.user_id
and naughty_events.table_name=naughty_table_to_url_map.table_name(+)
order by creation_date, upper(last_name), upper(first_names)"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a> \n
    <br>$offensive_text <br> " 
    
    if {[empty_string_p $url_stub]} {
	ns_write "<b>Date:</b> [util_AnsiDatetoPrettyDate $creation_date]<p>" 
    } else {
	ns_write "<b>Date:</b> [util_AnsiDatetoPrettyDate $creation_date]<br>
	<a href=\"$url_stub[ns_urlencode $the_key]\">Edit</a><p>" 
    }
}
 
ns_write "
</ul>

[ad_admin_footer]
"
