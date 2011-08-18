# /faq/admin/delete-2.tcl
#
# Deletes a q/a from the faq table
#
# by dh@arsdigita.com, created on 12/19/99
#
# $Id: delete-2.tcl,v 3.0.4.2 2000/04/28 15:10:25 carsten Exp $
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ad_page_variables {entry_id faq_id}

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check
set db [ns_db gethandle]
faq_admin_authorize $db $faq_id

ns_db dml $db "delete from faq_q_and_a where entry_id = $entry_id"

ns_db releasehandle $db

ad_returnredirect "one?[export_url_scope_vars faq_id]"










