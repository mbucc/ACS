# /admin/contest/index.tcl

ad_page_contract {
    @cvs-id index.tcl,v 3.4.2.3 2000/09/22 01:34:36 kevin Exp
} {
}

set html "[ad_admin_header "All [ad_system_name] Contests"]

<h2>Contests</h2>

[ad_admin_context_bar "Contests"]

<hr>

<h3>Active Contests</h3>
<ul>
"

set sql "select domain_id, pretty_name, home_url
from contest_domains
where sysdate between start_date and end_date
order by upper(pretty_name)"

set counter 0
db_foreach contest_domains $sql {
    incr counter
    append html "<li>$pretty_name : <a href=\"$home_url\">home URL</a> | <a href=\"/contest/entry-form?[export_url_vars domain_id]\">generated entry form</a> |
<a href=\"manage-domain?[export_url_vars domain_id]\">management page</a>"
}

if { $counter == 0 } {
    append html "there are no live contests at present"
}

append html "
</ul>

<h3>Inactive Contests</h3>

<ul>
"

set sql "select domain_id, pretty_name, home_url
from contest_domains
where sysdate not between start_date and end_date
order by upper(pretty_name)"

set counter 0
db_foreach contests $sql {
    incr counter
    append html "<li>$pretty_name : <a href=\"$home_url\">home URL</a> | <a href=\"/contest/entry-form?[export_url_vars domain_id]\">generated entry form</a> |
<a href=\"manage-domain?[export_url_vars domain_id]\">management page</a>"
}

append html "

<p>
<li><a href=\"add-domain-choose-maintainer\">add a contest</a>

</ul>

[ad_admin_footer]
"

db_release_unused_handles
doc_return 200 text/html $html
