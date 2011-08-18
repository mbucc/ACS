# $Id: index.tcl,v 3.2 2000/03/10 20:00:54 markd Exp $

set the_page "[ad_header "All [ad_system_name] Contests"]

<h2>Contests</h2>

at [ad_site_home_link]

<hr>

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select domain_id, home_url, pretty_name
from contest_domains
where sysdate between start_date and end_date
order by upper(pretty_name)"]

set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter 
    append the_page "<li><a href=\"entry-form.tcl?[export_url_vars domain_id]\">$pretty_name</a>\n"
}

if { $counter == 0 } {
    append the_page "there are no live contests at present"
}

append the_page "</ul>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $the_page
