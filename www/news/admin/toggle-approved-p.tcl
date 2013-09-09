# /www/news/admin/toggle-approval-p.tcl
#

ad_page_contract {
    toggle the approval status for the new item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id toggle-approved-p.tcl,v 3.5.2.8 2000/08/16 20:50:33 luke Exp

    Note: if page is accessed through /groups pages then group_id and 
    group_vars_set are already set up in the environment by the 
    ug_serve_section. group_vars_set contains group related variables
    (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and
    group_navbar_list)
} {
    scope:optional
    group_id:integer,optional
    on_which_group:integer,optional
    on_what_id:integer,optional
    return_url:optional
    name:optional
    news_item_id:integer,notnull
}


set user_id [ad_verify_and_get_user_id]

ad_scope_error_check

news_admin_authorize $news_item_id

db_dml news_item_update "update news_items set approval_state = decode(approval_state, 'approved', 'disapproved', 'approved'), approval_user = :user_id, approval_date = sysdate, approval_ip_address = '[DoubleApos [ns_conn peeraddr]]' where news_item_id = :news_item_id"

ad_returnredirect "item?[export_url_vars news_item_id]"

