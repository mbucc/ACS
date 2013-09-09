# /www/news/admin/comment-toggle-approval.tcl
#

ad_page_contract {
    news item comment approval page

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id comment-toggle-approval.tcl,v 3.3.2.8 2000/08/03 19:13:25 tina Exp

    Note: if page is accessed through /groups pages then group_id and 
    group_vars_set are already set up in the environment by the 
    ug_serve_section. group_vars_set contains group related variables
    (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and
    group_navbar_list)
} {
    news_item_id:integer,notnull
    comment_id:integer,notnull
    scope:optional
    group_id:integer,optional
    public:optional
    contact_info_only:optional
    order_by:optional
}

ad_scope_error_check

db_dml news_comments_update "update general_comments 
               set approved_p = logical_negation(approved_p)
               where comment_id = :comment_id"

ad_returnredirect "item?[export_url_vars news_item_id]"



