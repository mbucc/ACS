# /www/display/get-complete-css.tcl

ad_page_contract {
    gets css from the database and returns the css file
    this file uses css_complete table

    @param Note: if page is accessed through /groups pages then group_id and group_vars_set are 
    already set up in the environment by the ug_serve_section. group_vars_set contains group 
    related variables (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
    group_type_url_p, group_context_bar_list and group_navbar_list)

    @author tarik@arsdigita.com
    @creation-date 12/22/99

    @cvs-id get-complete-css.tcl,v 3.1.2.5 2000/09/22 01:37:21 kevin Exp
} {
    scope:optional
    user_id:optional,integer
    group_id:optional,integer
    on_which_group_id:optional
    on_what_id:optional
}

ad_scope_error_check

doc_return  200 text/css [css_generate_complete_css]


