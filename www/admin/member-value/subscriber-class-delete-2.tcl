# /www/admin/member-value/subscriber-class-delete-2.tcl

ad_page_contract {
    Delete a subscriber class and move all its users to another subscriber class.
    @param subscriber_class the subscriber class to delete
    @param new_subscriber_class the subscriber for the users in the old subscriber class to move to
    @author mbryzek@arsdigita.com
    @creation-date Tue Jul 11 20:52:42 2000
    @cvs-id subscriber-class-delete-2.tcl,v 3.2.2.6 2000/09/22 01:35:32 kevin Exp

} {
    subscriber_class:notnull
    new_subscriber_class:notnull
}


set page_content "[ad_admin_header "Deleting $subscriber_class"]

<h2>Deleting $subscriber_class</h2>

[ad_admin_context_bar [list "" "Member Value"] "Deleting Subscriber Class"]

<hr>

Moving all the old subscribers to $new_subscriber_class ...

"

db_transaction {

db_dml mv_update_subscriber_class "update users_payment set subscriber_class = :new_subscriber_class where subscriber_class = :subscriber_class" 

append page_content " .. done. <p> Now deleting the subscriber class from mv_monthly_rates... " 

db_dml mv_delete_subscriber_class "delete from mv_monthly_rates where subscriber_class = :subscriber_class" 
}

db_release_unused_handles

append page_content " ... done.

[ad_admin_footer]
"

doc_return  200 text/html $page_content

