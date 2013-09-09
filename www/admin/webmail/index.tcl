# /admin/webmail/index.tcl

ad_page_contract {
    Display list of mail domains we handle on this server.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id index.tcl,v 1.4.6.4 2000/09/22 01:36:38 kevin Exp
} {}

set results ""

db_foreach domains {
    select short_name, full_domain_name
    from wm_domains
    order by short_name
} {
    append results "<li><a href=\"domain-one?[export_url_vars short_name]\">$full_domain_name</a>\n"
} if_no_rows {
    set results "<li>No domains currently handled.\n"
}



doc_return  200 text/html "[ad_admin_header "WebMail Administration"]
<h2>WebMail Administration</h2>

[ad_admin_context_bar "WebMail Admin"]

<hr>

Domains we handle email for:

<ul>
$results
<p>
<a href=\"domain-add\">Add a domain</a>
</ul>

<p>

<a href=\"problems\">administer common errors</a>

<h3>Mailing Lists</h3>

<a href=\"list-create.tcl\">Create a new list</a>

[ad_admin_footer]
"
