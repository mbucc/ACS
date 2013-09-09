# /faq/admin/faq-edit-2.tcl
# 

ad_page_contract {
    Deletes a FAQ (defined by faq_id) from the database

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id faq-edit-2.tcl,v 3.3.2.6 2000/07/23 20:15:44 luke Exp

    Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
    the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    faq_id:integer,notnull
    faq_name:notnull
    scope:optional
    group_id:integer,optional
}


ad_scope_error_check

faq_admin_authorize $faq_id

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
    ad_scope_return_complaint $error_count $error_text
    return
}

#-------------------------------------

# updates the name of the FAQ

db_dml faq_name_update "
update faqs 
set faq_name = :faq_name 
where faq_id = :faq_id"

db_release_unused_handles

ad_returnredirect "one?[export_url_vars faq_id]"

