# $Id: faq-delete-2.tcl,v 3.0.4.1 2000/04/28 15:10:26 carsten Exp $
# File:     /faq/admin/faq-delete-2.tcl
# Date:     12/19/99
# Contact:  dh@arsdigita.com
# Purpose:  deletes a FAQ (defined by faq_id) from the database
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ad_page_variables {faq_id}

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)
# faq_id

ad_scope_error_check
set db [ns_db gethandle]
faq_admin_authorize $db $faq_id

ns_db dml $db "begin transaction"

# delete the contents of the FAQ (question and answers)
ns_db dml $db "delete from faq_q_and_a where faq_id = $faq_id"

# delete the FAQ properties (name, associated group, scope)
ns_db dml $db "delete from faqs where faq_id = $faq_id"

ns_db dml $db "end transaction"

ad_returnredirect index.tcl?[export_url_scope_vars]


