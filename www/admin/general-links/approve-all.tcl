# /admin/general-links/approve-all.tcl
#
# Author: tzumainn@arsdigita.com, 2/01/2000
#
# Approves a link and all its associations
#
# $Id: approve-all.tcl,v 3.0.4.1 2000/04/28 15:09:04 carsten Exp $
#--------------------------------------------------------

ad_page_variables {link_id {return_url "index.tcl"}}

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

set current_approval_status [database_to_tcl_string $db "select approved_p from general_links where link_id = $link_id"]

if { $current_approval_status == "f" } {
    ns_db dml $db "update general_links set approved_p = 't', last_approval_change = sysdate where link_id = $link_id"
}

ns_db dml $db "update site_wide_link_map set approved_p = 't' where link_id = $link_id"

ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect $return_url
