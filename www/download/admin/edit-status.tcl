# $Id: edit-status.tcl,v 3.0.6.3 2000/05/18 00:05:16 ron Exp $
# File:     /admin/download/edit-status.tcl
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# version_id status

ad_scope_error_check

set db [ns_db gethandle]
download_version_admin_authorize $db $version_id

ns_db dml $db "
update download_versions
set status='$QQstatus'
where version_id=$version_id
"

ad_returnredirect "view-one-version.tcl?[export_url_scope_vars version_id]"