# File: /admin/general-links/toggle-link-approved-p.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
# toggles approved_p of link 
#
# $Id: toggle-link-approved-p.tcl,v 3.1.2.1 2000/04/28 15:09:06 carsten Exp $
#--------------------------------------------------------

ad_page_variables {link_id {return_url "index.tcl"} approved_p}

set current_user_id [ad_maybe_redirect_for_registration]

set db [ns_db gethandle]

ns_db dml $db "update general_links set approved_p = '$approved_p', last_approval_change = sysdate, approval_change_by = $current_user_id where link_id = $link_id"

ns_db releasehandle $db

ad_returnredirect $return_url

