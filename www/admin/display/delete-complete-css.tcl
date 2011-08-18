# $Id: delete-complete-css.tcl,v 3.0.4.1 2000/04/28 15:08:33 carsten Exp $
# File:     /admin/diplay/delete-complete-css-2.tcl
# Date:     12/26/99
# Author:   ahmeds@arsdigita.com
# Purpose:  deleting cascaded style sheet properties
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe return_url, selector, property
# maybe scope, maybe scope related variables (group_id, user_id)

if { ![info exists return_url] } {
    set return_url "index.tcl?[export_url_scope_vars]"
}

ad_scope_error_check

set db [ns_db gethandle ]

ns_db dml $db "
delete from css_complete
where selector = '$selector'
and property = '$property'
and [ad_scope_sql]
"

ns_db releasehandle $db

ad_returnredirect $return_url
