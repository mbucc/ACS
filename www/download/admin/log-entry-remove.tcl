# $Id: log-entry-remove.tcl,v 3.1.6.3 2000/05/18 00:05:17 ron Exp $
# File:     /admin/download/log-entry-remove.tcl
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  removes this log entry
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# log_id return_url

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

ns_db dml $db "delete from download_log where log_id=$log_id"

ad_returnredirect  $return_url