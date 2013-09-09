# /www/admin/display/delete-complete-css.tcl

ad_page_contract {
    deleting cascaded style sheet properties
    @param Note: if page is accessed through /groups pages then group_id and group_vars_set are 
    already set up in the environment by the ug_serve_section. group_vars_set contains group 
    related variables (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
    group_type_url_p, group_context_bar_list and group_navbar_list)

    @param selector
    @param property

    @author ahmeds@arsdigita.com
    @creation-date 12/26/1999

    @cvs-id delete-complete-css.tcl,v 3.1.6.6 2000/07/21 03:56:41 ron Exp
} {
    return_url:optional
    selector
    property
    scope:optional
    user_id:optional,integer
}


if { ![info exists return_url] } {
    set return_url "index.tcl?[export_url_scope_vars]"
}

ad_scope_error_check

db_dml display_delete_query "
delete from css_complete
where selector = ':selector'
and property = ':property'
and [ad_scope_sql]"

db_release_unused_handles

ad_returnredirect $return_url


