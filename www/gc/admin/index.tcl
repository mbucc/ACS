# index.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id index.tcl,v 3.2.6.7 2001/01/10 19:13:13 khy Exp

} {}

ad_maybe_redirect_for_registration

set user_id [ad_get_user_id]

append html "[ad_admin_header "Classified Administration"]

<h2>Classified Administration</h2>

[ad_context_bar_ws_or_index [list "/gc/" "Classifieds"] "Classifieds Admin"]

<hr>
<ul>

<h4>Active domains</h4>"

set sql "select * 
from ad_domains
where ad_admin_group_member_p('gc',domain,:user_id) = 't'
order by active_p desc, upper(domain)"

set count 0
set inactive_title_shown_p 0

db_foreach gc_admin_index_domain_list $sql {
    
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

    append html "<li><a href=\"domain-top?domain_id=$domain_id\">$domain</a>\n"
    incr count
}

if { $count == 0 } {
    append html "you're not an administrator of any domains"
}

append html "
</ul>
<br>

<blockquote>
<h4>Action </h4>
 <a href=\"domain-add\">Add Domain</a>
</blockquote>

[ad_admin_footer]"

doc_return  200 text/html $html
