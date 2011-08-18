# $Id: edit-visibility.tcl,v 3.0.6.1 2000/04/12 09:00:45 ron Exp $
# File:     /admin/download/edit-visibility.tcl
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  changes the visibility of the downloadable version
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# version_id visibility

ad_scope_error_check

set db [ns_db gethandle]
download_version_admin_authorize $db $version_id

set counter [database_to_tcl_string $db "select count(*)
from download_rules 
where version_id = $version_id"]

if { $counter > 0 } { 
    ns_db dml $db "
    update download_rules
    set visibility='$QQvisibility'
    where version_id=$version_id
    "
} else {

    set rule_id [database_to_tcl_string $db "select download_rule_id_sequence.nextval from dual"]
    set download_id [database_to_tcl_string $db "select download_id from download_versions where version_id = $version_id"]

    ns_db dml $db "insert into download_rules
    (rule_id , version_id, download_id, visibility)
    values
    ($rule_id , $version_id, $download_id, '$QQvisibility')"
}

ns_returnredirect "view-one-version.tcl?[export_url_scope_vars version_id]"