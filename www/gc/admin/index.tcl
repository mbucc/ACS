# $Id: index.tcl,v 3.1 2000/03/10 23:58:50 curtisg Exp $
ad_maybe_redirect_for_registration

set user_id [ad_get_user_id]

append html "[ad_admin_header "Classified Administration"]

<h2>Classified Administration</h2>

[ad_context_bar_ws_or_index [list "/gc/" "Classifieds"] "Classifieds Admin"]

<hr>
<ul>

<h4>Active domains</h4>"

set db [gc_db_gethandle]

set selection [ns_db select $db "select * 
from ad_domains
where ad_admin_group_member_p('gc',domain,$user_id) = 't'
order by active_p desc, upper(domain)"]

set count 0
set inactive_title_shown_p 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $active_p == "f" } {
	if { $inactive_title_shown_p == 0 } {
	    # we have not shown the inactive title yet
	    if { $count == 0 } {
		append html "<li>No active domains"
	    }
	    set inactive_title_shown_p 1
	    append html "<h4>Inactive domains</h4>"
	}
    } else {
    }

    set_variables_after_query

    append html "<li><a href=\"domain-top.tcl?domain_id=$domain_id\">$domain</a>\n"
    incr count
}

if { $count == 0 } {
    append html "you're not an administrator of any domains"
}

append html "

</ul>

[ad_admin_footer]"

ns_db releasehandle $db
ns_return 200 text/html $html
