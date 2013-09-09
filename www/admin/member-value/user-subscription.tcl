# /www/admin/member-value/user-subscription.tcl

ad_page_contract {
    Form to place the user in a new subscription class.
    @param user_id
    @author mbryzek@arsdigita.com
    @creation-date Tue Jul 11 19:49:48 2000
    @cvs-id user-subscription.tcl,v 3.2.2.5 2000/09/22 01:35:32 kevin Exp

} {
   user_id:integer,notnull 
}


db_1row project_user_name_query "select unique first_names, last_name from users where user_id = :user_id" 

set page_content "[ad_admin_header "Subscription for $first_names $last_name"]

<h2>Subscription Info</h2>

[ad_admin_context_bar [list "" "Member Value"] "Subscription info"]

<hr>
"

if {[db_0or1row projects_subscriber_class_query "select subscriber_class from users_payment where user_id = :user_id"] == 0} {
    append page_content"
<form method=POST action=\"user-subscription-classify\">
<input type=hidden name=user_id value=\"$user_id\">
Place user in a subscription class:
<select name=subscriber_class>
[db_html_select_options subscriber_classes_select_options "select subscriber_class from mv_monthly_rates order by rate"]
</select>
<input type=submit value=\"Choose\">
</form>
"
} else {
    append page_content "Current subscription class:  <b>$subscriber_class</b>

<p>

<form method=POST action=\"user-subscription-classify\">
<input type=hidden name=user_id value=\"$user_id\">
Place user in a new subscription class:
<select name=subscriber_class>
[db_html_select_options -select_option $subscriber_class selection_option_subscriber_class "select subscriber_class from mv_monthly_rates order by rate"]
</select>
<input type=submit value=\"Choose\">
</form>
"
}

db_release_unused_handles

append page_content "
</ul>
[ad_admin_footer]
"
doc_return  200 text/html $page_content
