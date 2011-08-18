# /www/download/admin/download-remove-version-2.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  target page to remove version file
#
# $Id: download-remove-version-2.tcl,v 1.1.2.2 2000/04/28 15:09:57 carsten Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# version_id 

ad_scope_error_check

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "
select download_id
from   download_versions
where  version_id = $version_id "]

if { [empty_string_p $selection] } {
    ad_scope_return_complaint 1 "Download version does not exist" $db
    return
}

set_variables_after_query

download_version_delete $db $version_id

ad_returnredirect view-versions.tcl?[export_url_scope_vars download_id]

