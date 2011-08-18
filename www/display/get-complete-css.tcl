# $Id: get-complete-css.tcl,v 3.0 2000/02/06 03:37:48 ron Exp $
# File:     /css/get-complete-css.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  gets css from the database and returns the css file
#           this file uses css_complete table
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]
ns_return 200 text/css [css_generate_complete_css $db]







