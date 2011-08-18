#
# /www/news/admin/toggle-approval-p.tcl
#
# toggle the approval status for the new item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: toggle-approved-p.tcl,v 3.1.2.2 2000/04/28 15:11:15 carsten Exp $

# Note: if page is accessed through /groups pages then group_id and 
# group_vars_set are already set up in the environment by the 
# ug_serve_section. group_vars_set contains group related variables
# (group_id, group_name, group_short_name, group_admin_email, 
# group_public_url, group_admin_url, group_public_root_url,
# group_admin_root_url, group_type_url_p, group_context_bar_list and
# group_navbar_list)

set_the_usual_form_variables
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe return_url, name
# news_item_id

if { ![info exists user_id] } {
    set user_id [ad_verify_and_get_user_id]
}

ad_scope_error_check
set db [ns_db gethandle]
news_admin_authorize $db $news_item_id

ns_db dml $db "update news_items set approval_state = decode(approval_state, 'approved', 'disapproved', 'approved'), approval_user = $user_id, approval_date = sysdate, approval_ip_address = '[DoubleApos [ns_conn peeraddr]]' where news_item_id = $news_item_id"

ad_returnredirect "item.tcl?[export_url_scope_vars news_item_id]"




