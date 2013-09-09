# /www/admin/gc/index.tcl
ad_page_contract {
    Shows active and inactive domains, allowing you to toggle between states.
    
    @author xxx
    @creation-date unknown
    @cvs-id index.tcl,v 3.2.6.6 2000/09/22 01:35:23 kevin Exp
} {

}

set html "
[ad_admin_header "Classified Administration"]

<h2>Classified Administration</h2>

[ad_admin_context_bar "Classifieds"]

<hr>
<ul>

<h4>Active domains</h4>"


set count 0
set inactive_title_shown_p 0

db_foreach active_domains "
select domain_id,
       domain,
       active_p
from   ad_domains
order by active_p desc, upper(domain)" {
    # shows active and inactive domains
    
    if { $active_p == "f" } {
	if { $inactive_title_shown_p == 0 } {
	    # we have not shown the inactive title yet
	    if { $count == 0 } {
		append html "<li>No active domains"
	    }
	    set inactive_title_shown_p 1
	    append html "<h4>Inactive domains</h4>"
	}
	set anchor "activate"
    } else {
	set anchor "deactivate"
    }

    append html "<li><a href=\"domain-top?[export_url_vars domain_id]\">$domain</a>\n
    (<a href=\"toggle-active-p?[export_url_vars domain_id]\">$anchor</a>)\n"
    incr count
}

append html "

<p>

<li><a href=\"domain-add\">create a new domain</a>

</ul>

[ad_admin_footer]"


doc_return  200 text/html $html
