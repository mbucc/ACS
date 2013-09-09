# domain-one.tcl

ad_page_contract {
    Display users for one mail domain.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id domain-one.tcl,v 1.4.2.4 2000/09/22 01:36:38 kevin Exp
} {
    short_name
}

set full_domain_name [db_string full_domain_name "select full_domain_name
from wm_domains
where short_name = :short_name"]

set results ""

db_foreach users {
    select email_user_name, u.user_id, first_names || ' ' || last_name as full_user_name
    from wm_email_user_map eum, users u
    where eum.domain = :short_name
    and eum.user_id = u.user_id
    order by email_user_name
} {
    append results "<li>$email_user_name@$full_domain_name: <a href=\"/shared/community-member?user_id=$user_id\">$full_user_name</a>\n"
} if_no_rows {
    set results "<li>No users.\n"
}

set full_domain_name [db_string full_domain_name "select full_domain_name
from wm_domains
where short_name = :short_name"]



doc_return  200 text/html "[ad_admin_header "One Domain"]
<h2>$full_domain_name</h2>

[ad_admin_context_bar [list "index.tcl" "WebMail Admin"] "One Domain"]

<hr>

<ul>
[export_form_vars short_name]
$results
<p>
<a href=\"domain-add-user?[export_url_vars short_name]\">Add a user</a>
</ul>

[ad_admin_footer]
"
