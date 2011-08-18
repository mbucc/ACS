#
# /www/news/admin/comment-toggle-approval.tcl
#
# news item comment approval page
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: comment-toggle-approval.tcl,v 1.1.2.2 2000/04/28 15:11:15 carsten Exp $

# Note: if page is accessed through /groups pages then group_id and 
# group_vars_set are already set up in the environment by the 
# ug_serve_section. group_vars_set contains group related variables
# (group_id, group_name, group_short_name, group_admin_email, 
# group_public_url, group_admin_url, group_public_root_url,
# group_admin_root_url, group_type_url_p, group_context_bar_list and
# group_navbar_list)

set_the_usual_form_variables
# news_item_id, comment_id
# maybe scope, maybe scope related variables (group_id, public)
# maybe contact_info_only, maybe order_by

ad_scope_error_check
set db [ns_db gethandle]
#news_admin_authorize $db $news_item_id

ns_db dml $db "update general_comments set approved_p = logical_negation(approved_p) where comment_id = $comment_id"

ad_returnredirect "item.tcl?[export_url_scope_vars news_item_id]"