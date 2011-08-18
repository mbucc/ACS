# domain-one.tcl
# Display users for one mail domain.
# Written by jsc@arsdigita.com.


ad_page_variables {short_name}

set db [ns_db gethandle]

set full_domain_name [database_to_tcl_string $db "select full_domain_name
from wm_domains
where short_name = '$QQshort_name'"]

set selection [ns_db select $db "select email_user_name, u.user_id, first_names || ' ' || last_name as full_user_name
from wm_email_user_map eum, users u
where eum.domain = '$QQshort_name'
and eum.user_id = u.user_id
order by email_user_name"]

set results ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    
    append results "<li>$email_user_name@$full_domain_name: <a href=\"/shared/community-member.tcl?user_id=$user_id\">$full_user_name</a>\n"
}

if { [empty_string_p $results] } {
    set results "<li>No users.\n"
}

set full_domain_name [database_to_tcl_string $db "select full_domain_name
from wm_domains
where short_name = '$QQshort_name'"]

ns_db releasehandle $db

ns_return 200 text/html "[ad_admin_header "One Domain"]
<h2>$full_domain_name</h2>

[ad_admin_context_bar [list "index.tcl" "WebMail Admin"] "One Domain"]

<hr>

<ul>
[export_form_vars short_name]
$results
<p>
<a href=\"domain-add-user.tcl?[export_url_vars short_name]\">Add a user</a>
</ul>

[ad_admin_footer]
"
