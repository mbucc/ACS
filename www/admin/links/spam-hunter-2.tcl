# $Id: spam-hunter-2.tcl,v 3.0 2000/02/06 03:24:50 ron Exp $
set_the_usual_form_variables

# url

ReturnHeaders

ns_write "[ad_admin_header "$url"]

<h2>$url</h2>

[ad_admin_context_bar [list "index.tcl" "Links"] [list "spam-hunter.tcl" "Spam Hunter"] "One potential spammer"]


<hr>

<ul>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select links.page_id, links.user_id, link_title, link_description, links.status, links.originating_ip, links.posting_time, sp.url_stub, sp.page_title, users.first_names, users.last_name
from links, static_pages sp, users 
where links.url = '$QQurl'
and links.page_id = sp.page_id
and links.user_id = users.user_id"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li>added by <a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a>
on [util_AnsiDatetoPrettyDate $posting_time]
to <a href=\"blacklist.tcl?[export_url_vars page_id url]\">$url_stub</a>
"
}

ns_write "</ul>

[ad_admin_footer]
"




