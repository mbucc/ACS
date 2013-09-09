# /www/admin/display/toggle-logo-enabled.tcl

ad_page_contract {
    Display settings administration page.
    @param Note: if this page is accessed through /groups/admin pages then
    group_id, group_name, short_name and admin_email are already
    set up in the environment by the ug_serve_section

    @param logo_id
    @param scope, group_id, user_id are optional

    @author tarik@arsdigita.com
    @creation-date 12/27/99

    @cvs-id toggle-logo-enabled.tcl,v 3.1.6.6 2000/07/21 03:56:42 ron Exp
} {
    logo_id:integer
    scope:optional
    group_id:optional,integer
    user_id:optional,integer
}


ad_scope_error_check

db_dml display_update_query "update page_logos 
set logo_enabled_p = logical_negation(logo_enabled_p) 
where logo_id = :logo_id"

db_release_unused_handles

ad_returnredirect "upload-logo.tcl?[export_url_scope_vars]"
