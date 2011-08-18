# $Id: whos-online.tcl,v 3.0 2000/02/06 03:54:37 ron Exp $
set connected_user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

set selection [ns_db select $db "select user_id, first_names, last_name, email
from users
where last_visit > sysdate - [ad_parameter LastVisitUpdateInterval "" 600]/86400
order by upper(last_name), upper(first_names), upper(email)"]


set users ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $connected_user_id != 0 } {
	append users "<li><a href=\"/shared/community-member.tcl?user_id=$user_id\">$first_names $last_name</a> ($email)\n"
    } else {
	# random tourist, let's not show email address
	append users "<li><a href=\"/shared/community-member.tcl?user_id=$user_id\">$first_names $last_name</a>\n"
    }
}

ns_db releasehandle $db

if ![ad_parameter EnabledP chat 0] {
    set chat_link ""
} else {
    set chat_link "This page is mostly useful in conjuction with 
<a href=\"/chat/\">[chat_system_name]</a>."
}

ns_return 200 text/html "[ad_header "Who's Online?"]

[ad_decorate_top "<h2>Who's Online?</h2>

[ad_context_bar_ws_or_index "Who's Online"]
" [ad_parameter WhosOnlineDecoration]]

<hr>

$chat_link

<ul>
$users
</ul>

These are the registered users who have 
requested a page from this server within the last
[ad_parameter LastVisitUpdateInterval ""] seconds.

<p>

On a public Internet service, the number of casual surfers
(unregistered) will outnumber the registered users by at least 10 to
1.  Thus there could be many more people using this service than it
would appear.

[ad_footer]
"
