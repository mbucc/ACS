# /www/admin/member-value/subscriber-class-delete.tcl

ad_page_contract {
    Form to delete a subscriber class.
    
    @param subscriber_class    
    @author mbryzek@arsdigita.com
    @creation-date Tue Jul 11 20:47:10 2000
    @cvs-id subscriber-class-delete.tcl,v 3.1.6.6 2000/09/22 01:35:32 kevin Exp

} {
    subscriber_class:notnull
}

set page_content "[ad_admin_header "Delete $subscriber_class"]

<h2>Delete subscriber class $subscriber_class</h2>

[ad_admin_context_bar [list "" "Member Value"] "Delete Subscriber Class"]

<hr>

<form method=GET action=\"subscriber-class-delete-2\">
[export_form_vars subscriber_class]

<ul>
<li>Number of subscribers presently in this class:

"

set n_subscribers [db_string mv_users_payment_count "select count(*) from users_payment where subscriber_class = :subscriber_class"]

db_release_unused_handles

set bind_vars [ad_tcl_vars_to_ns_set subscriber_class]

append page_content "$n_subscribers"
append page_content "<li>subscriber class into which to move the above folks:
<select name=new_subscriber_class>
[db_html_select_options -bind $bind_vars subscriber_classes_select_options "select subscriber_class 
from mv_monthly_rates
where subscriber_class <> :subscriber_class
order by rate"]
</select>
</ul>

<center>
<input type=submit value=\"Yes, I'm absolutely sure that I want to delete $subscriber_class\">
</center>
</form>

[ad_admin_footer]
"

doc_return  200 text/html $page_content
