# $Id: toggle-logo-enabled.tcl,v 3.0.4.1 2000/04/28 15:08:34 carsten Exp $
# File:     /display/toggle-logo-enabled.tcl
# Date:     12/27/99
# Contact:  tarik@arsdigita.com
# Purpose:  display settings administration page
#
# Note:     if this page is accessed through /groups/admin pages then
#           group_id, group_name, short_name and admin_email are already
#           set up in the environment by the ug_serve_section

set_form_variables
# maybe scope, maybe scope related variables (group_id, user_id)
# logo_id

ad_scope_error_check

set db [ns_db gethandle]

ns_db dml $db "
update page_logos
set logo_enabled_p=logical_negation(logo_enabled_p)
where logo_id=$logo_id
"

ad_returnredirect "upload-logo.tcl?[export_url_scope_vars]"
