# /www/admin/display/edit-complete-css-2.tcl

ad_page_contract {
    target page for setting up/editing  cascaded style sheet properties

    @param Note: if page is accessed through /groups pages then group_id and group_vars_set are 
    already set up in the environment by the ug_serve_section. group_vars_set contains group 
    related variables (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
    group_type_url_p, group_context_bar_list and group_navbar_list)



    @author ahmeds@arsdigita.com
    @creation-date 12/26/1999

    @cvs-id edit-complete-css-2.tcl,v 3.2.2.6 2000/07/21 03:56:41 ron Exp
} {
    return_url:optional
    scope:optional
    group_id:optional,integer
    user_id:optional,integer
}



if { ![info exists return_url] } {
    set return_url "index.tcl?[export_url_scope_vars]"
}

ad_scope_error_check

set query_sql "select selector, property from css_complete where [ad_scope_sql]"

db_foreach display_select_query $query_sql {
    db_dml display_update_query "update css_complete
    	set value = '[set css\_$selector\_$property]'
    	where selector='$selector'
    	and property='$property'
    	and [ad_scope_sql]"
}

db_release_unused_handles

ad_returnredirect $return_url

