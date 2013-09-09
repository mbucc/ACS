# file: faq/admin/faq-delete-2.tcl
#

ad_page_contract {
    File:     /faq/admin/faq-delete-2.tcl
    Purpose:  deletes a FAQ (defined by faq_id) from the database

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id faq-delete-2.tcl,v 3.2.2.6 2000/07/23 20:15:43 luke Exp

    Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
    the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    faq_id:integer,notnull
    scope:optional
    group_id:integer,optional
}


ad_scope_error_check

faq_admin_authorize $faq_id

db_transaction {
    # delete the contents of the FAQ (question and answers)
    db_dml faq_delete "delete from faq_q_and_a where faq_id = :faq_id"

    # delete the FAQ properties (name, associated group, scope)
    db_dml faq_delete "delete from faqs where faq_id = :faq_id"
    db_release_unused_handles
}

ad_returnredirect index.tcl?[export_url_vars]

