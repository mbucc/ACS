# /www/admin/display/add-complete-css-property-2.tcl

ad_page_contract {
    setting up cascaded style sheet properties of a chosen selector
    Note: if page is accessed through /groups pages then group_id and group_vars_set 
    are already set up in the environment by the ug_serve_section. group_vars_set 
    contains group related variables (group_id, group_name, group_short_name, 
    group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @param css_id
    @param selector
    @param property
    @param value

    @author ahmeds@arsdigita.com
    @creation-date 12/26/1999

    @cvs-id add-complete-css-property-2.tcl,v 3.0.12.7 2001/01/10 17:28:14 khy Exp
} {
    return_url:optional
    css_id:integer,verify
    selector
    property
    value
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
}



if { ![info exists return_url] } {
    set return_url "index.tcl?[export_url_scope_vars]"
}

ad_scope_error_check

#set bind_vars [ad_tcl_vars_to_ns_set css_id selector property value]
#ad_dbclick_check_dml -bind $bind_vars display_insert_query css_complete css_id $css_id $return_url "
#insert into css_complete 
#([ad_scope_cols_sql], css_id, selector, property, value) 
#values ([ad_scope_vals_sql], :css_id, :selector, :property, :value)"

db_dml display_insert_query "insert into css_complete 
([ad_scope_cols_sql], css_id, selector, property, value) 
values ([ad_scope_vals_sql], :css_id, :selector, :property, :value)"

db_release_unused_handles

ad_returnredirect $return_url




