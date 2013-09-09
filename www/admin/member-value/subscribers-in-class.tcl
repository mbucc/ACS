# /www/admin/member-value/subscribers-in-class.tcl

ad_page_contract {
    List all the subscribers in a class.
    
    @param subscriber_class
    @author mbryzek@arsdigita.com
    @creation-date Tue Jul 11 20:40:39 2000
    @cvs-id subscribers-in-class.tcl,v 3.1.6.6 2000/09/22 01:35:32 kevin Exp

} {
    subscriber_class:notnull
}

set page_content "[ad_admin_header "$subscriber_class subscribers"]

<h2>$subscriber_class subscribers</h2>

[ad_admin_context_bar [list "" "Member Value"] "Subscribers in class"]

<hr>

<ul>
"

set sql "select u.user_id, u.first_names, u.last_name, u.email
from users u, users_payment up
where u.user_id = up.user_id
and up.subscriber_class = :subscriber_class
order by upper(u.last_name), upper(u.first_names)"

db_foreach mv_user_info_query $sql {
    append page_content "<li><a href=\"../../shared/community-member?user_id=$user_id\">$first_names $last_name</a> ($email)\n"
} if_no_rows {
    append page_content "<li>There's no subscriber in this class."
}

db_release_unused_handles

append page_content "
</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_content