# domain-add-user-2.tcl
# Assign email address to ACS user.
# Written by jsc@arsdigita.com.


ad_page_variables {username short_name}

set db [ns_db gethandle]

set full_domain_name [database_to_tcl_string $db "select full_domain_name
from wm_domains
where short_name = '$QQshort_name'"]

ns_db releasehandle $db

ns_return 200 text/html "[ad_admin_header "Specify Recipient"]
<h2>$full_domain_name</h2>

<hr>

Specify recipient who will receive email sent to $username@$full_domain_name:

<form action=\"/user-search.tcl\">
<input type=hidden name=target value=\"/admin/webmail/domain-add-user-3.tcl\">
<input type=hidden name=passthrough value=\"username short_name\">
[export_form_vars username short_name]

Email: <input type=text name=email size=50 value=\"[philg_quote_double_quotes $username]\">
<p>
or
<p>
Last Name: <input type=text name=last_name size=50>

<center>
<input type=submit value=\"Find User\">
</center>

[ad_admin_footer]
"