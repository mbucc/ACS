# domain-add-user.tcl
# Present form for adding a new user.
# Written by jsc@arsdigita.com.

ad_page_variables {short_name}

set db [ns_db gethandle]

set full_domain_name [database_to_tcl_string $db "select full_domain_name
from wm_domains
where short_name = '$QQshort_name'"]

ns_db releasehandle $db

ns_return 200 text/html "[ad_admin_header "Add User"]
<h2>$full_domain_name</h2>

[ad_admin_context_bar [list "index.tcl" "WebMail Admin"] [list "domain-one.tcl?[export_url_vars short_name]" "One Domain"] "Create Account"]

<hr>

Create a new account in this domain:

<form action=\"domain-add-user-2.tcl\">
[export_form_vars short_name]
Email address: <input type=text name=username size=10>@$full_domain_name
</form>

[ad_admin_footer]
"
