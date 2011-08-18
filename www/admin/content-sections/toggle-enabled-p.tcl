# $Id: toggle-enabled-p.tcl,v 3.0.4.1 2000/04/28 15:08:30 carsten Exp $
# File:     /admin/content-sections/toggle-enabled-p.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  toggles enabled_p column of the section
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# section_key

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

ns_db dml $db "
update content_sections 
set enabled_p = logical_negation(enabled_p) where 
[ad_scope_sql] and section_key = '$QQsection_key'
"

ad_returnredirect index.tcl

