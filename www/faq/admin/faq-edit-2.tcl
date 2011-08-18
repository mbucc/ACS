# /faq/admin/faq-edit-2.tcl
# 
# Deletes a FAQ (defined by faq_id) from the database
#
# by dh@arsdigita.com, created on 12/19/99
#
# $Id: faq-edit-2.tcl,v 3.0.4.2 2000/04/28 15:10:26 carsten Exp $
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ad_page_variables {faq_id}

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)
# faq_id , faq_name

ad_scope_error_check
set db [ns_db gethandle]
faq_admin_authorize $db $faq_id

# -- form validation ------------------

set error_count 0
set error_text ""


if {![info exists faq_id] || [empty_string_p $faq_id] } {
    incr error_count
    append error_text "<li>FAQ id was not supplied."
}

if {![info exists faq_name] || [empty_string_p [string trim $faq_name]] } {
    incr error_count
    append error_text "<li>You must supply a name for the new FAQ."
}

if {$error_count > 0 } {
    ad_scope_return_complaint $error_count $error_text $db
    return
}

#-------------------------------------


# updates the name of the FAQ
ns_db dml $db "
update faqs 
set faq_name='$QQfaq_name' 
where faq_id = $faq_id "


ns_db releasehandle $db

ad_returnredirect "one?[export_url_scope_vars faq_id]"





