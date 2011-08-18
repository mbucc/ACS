# $Id: index.tcl,v 3.2 2000/03/10 20:57:32 markd Exp $
ReturnHeaders

ns_write "[ad_admin_header "All [ad_system_name] Contests"]

<h2>Contests</h2>

[ad_admin_context_bar "Contests"]


<hr>

<h3>Active Contests</h3>
<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select domain_id, domain, pretty_name, home_url
from contest_domains
where sysdate between start_date and end_date
order by upper(pretty_name)"]

set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    ns_write "<li>$pretty_name : <a href=\"$home_url\">home URL</a> | <a href=\"/contest/entry-form.tcl?[export_url_vars domain_id]\">generated entry form</a> |
<a href=\"manage-domain.tcl?[export_url_vars domain_id]\">management page</a>"
}

if { $counter == 0 } {
    ns_write "there are no live contests at present"
}

ns_write "
</ul>

<h3>Inactive Contests</h3>

<ul>
"

set selection [ns_db select $db "select domain_id, domain, pretty_name, home_url
from contest_domains
where sysdate not between start_date and end_date
order by upper(pretty_name)"]

set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    ns_write "<li>$pretty_name : <a href=\"$home_url\">home URL</a> | <a href=\"/contest/entry-form.tcl?[export_url_vars domain_id]\">generated entry form</a> |
<a href=\"manage-domain.tcl?[export_url_vars domain_id]\">management page</a>"
}


ns_write "

<p>
<li><a href=\"add-domain-choose-maintainer.adp\">add a contest</a>

</ul>

[ad_admin_footer]
"
