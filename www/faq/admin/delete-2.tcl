# /faq/admin/delete-2.tcl
#

ad_page_contract {
    Deletes a q/a from the faq table

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @creation-id delete-2.tcl,v 3.3.2.7 2000/07/23 20:15:42 luke Exp

    Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
    the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    entry_id:integer,notnull
    faq_id:integer,notnull
    scope:optional
    group_id:integer,optional
}


ad_scope_error_check

faq_admin_authorize $faq_id


db_dml faq_delete "delete from faq_q_and_a where entry_id = :entry_id"

db_release_unused_handles

ad_returnredirect "one?[export_url_vars faq_id]"

