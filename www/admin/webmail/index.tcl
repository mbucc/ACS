# /admin/webmail/index.tcl
# Display list of mail domains we handle on this server.
# Written by jsc@arsdigita.com.

set db [ns_db gethandle]

set selection [ns_db select $db "select short_name, full_domain_name
from wm_domains
order by short_name"]

set results ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    append results "<li><a href=\"domain-one.tcl?[export_url_vars short_name]\">$full_domain_name</a>\n"
}

if { [empty_string_p $results] } {
    set results "<li>No domains currently handled.\n"
}

ns_db releasehandle $db

ns_return 200 text/html "[ad_admin_header "WebMail Administration"]
<h2>WebMail Administration</h2>

[ad_admin_context_bar "WebMail Admin"]

<hr>

Domains we handle email for:

<ul>
$results
<p>
<a href=\"domain-add.tcl\">Add a domain</a>
</ul>

[ad_admin_footer]
"
