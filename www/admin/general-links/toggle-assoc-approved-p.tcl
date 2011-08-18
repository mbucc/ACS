# File: /admin/general-links/toggle-assoc-approved-p.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
# toggles approved_p of link association 
#
# $Id: toggle-assoc-approved-p.tcl,v 3.1.2.1 2000/04/28 15:09:06 carsten Exp $
#--------------------------------------------------------

ad_page_variables {map_id approved_p {return_url "view-associations.tcl?link_id=$link_id"}}

set current_user_id [ad_maybe_redirect_for_registration]

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

set link_id [database_to_tcl_string $db "select link_id from site_wide_link_map where map_id = $map_id"]

ns_db dml $db "update site_wide_link_map set approved_p = '$approved_p', approval_change_by = $current_user_id where map_id = $map_id"

ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect $return_url

