# domain-add-user.tcl

ad_page_contract {
    Present form for adding a new user.
    
    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id domain-add-user.tcl,v 1.3.6.5 2000/09/22 01:36:38 kevin Exp
} {
    short_name:notnull
}

set full_domain_name [db_string full_domain_name "select full_domain_name
from wm_domains
where short_name = :short_name"]



doc_return  200 text/html "[ad_admin_header "Add User"]
<h2>$full_domain_name</h2>

[ad_admin_context_bar [list "index.tcl" "WebMail Admin"] [list "domain-one.tcl?[export_url_vars short_name]" "One Domain"] "Create Account"]

<hr>

Create a new account in this domain:

<form action=\"domain-add-user-2\">
[export_form_vars short_name]
Email address: <input type=text name=username size=10>@$full_domain_name
</form>

[ad_admin_footer]
"
