# $Id: toggle-approved-p.tcl,v 3.0.4.1 2000/04/28 15:10:38 carsten Exp $
# File:     /general-comments/admin/toggle-approved_p.tcl
# Date:     01/06/99
# author :  philg@mit.edu
# Contact:  philg@mit.edu, tarik@arsdigita.com
# Purpose:  general comments administration main page
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_form_variables
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# comment_id  maybe return_url

if {![info exists return_url]} {
    set return_url "index.tcl"
}

set db [ns_db gethandle]

ns_db dml $db "update general_comments set approved_p = logical_negation(approved_p) where comment_id = $comment_id"

ad_returnredirect $return_url

