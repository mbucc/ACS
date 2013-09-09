# /www/display/get-logo.tcl

ad_page_contract {
    Gets logo from the database and returns the appropiate image file.

    @param Note: if page is accessed through /groups pages then group_id and group_vars_set are 
    already set up in the environment by the ug_serve_section. group_vars_set contains group 
    related variables (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
    group_type_url_p, group_context_bar_list and group_navbar_list)

    @author tarik@arsdigita.com
    @creation-date 12/27/99 

    @cvs-id get-logo.tcl,v 3.1.2.5 2000/07/21 03:59:15 ron Exp
} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    on_which_group_id:optional
    on_what_id:optional
}


ad_scope_error_check

set mime_type [db_string display_get_mime_type_query "select logo_file_type 
from page_logos 
where [ad_scope_sql]" ]

ReturnHeaders $mime_type

db_write_blob display_blob_query "select logo from page_logos where [ad_scope_sql]"

db_release_unused_handles 