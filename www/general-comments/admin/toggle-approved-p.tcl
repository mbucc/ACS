# /general-comments/admin/toggle-approved_p.tcl

ad_page_contract {
    general comments administration main page

    @author philg@mit.edu
    @creation-date 01/06/99
    @cvs-id toggle-approved-p.tcl,v 3.1.6.2 2000/07/25 08:34:20 kevin Exp
} {
    {scope ""}
    {group_id:integer ""}
    {on_which_group ""}
    {on_what_id ""}
    comment_id
    return_url
}

# Contact:  philg@mit.edu, tarik@arsdigita.com
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {![info exists return_url]} {
    set return_url "index.tcl"
}

db_dml approved_p_toggle {
    update general_comments set approved_p = logical_negation(approved_p) 
    where comment_id = :comment_id
}

ad_returnredirect $return_url

