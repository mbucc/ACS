# /admin/general-links/approve-all.tcl

ad_page_contract {
    Approves a link and all its associations

    @param link_id ID of link to approve
    @param return_url Where to return to when finished

    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @creation-date 2/01/2000
    @cvs-id approve-all.tcl,v 3.1.6.5 2000/07/24 17:27:17 ryanlee Exp
} {
    link_id:notnull,naturalnum
    {return_url "index"}
}

db_transaction {

    set current_approval_status [db_string select_curr_approval_status "select approved_p from general_links where link_id = :link_id"]

    if { $current_approval_status == "f" } {
	db_dml set_approval_status "update general_links set approved_p = 't', last_approval_change = sysdate where link_id = :link_id"
    }

    db_dml set_link_map_status "update site_wide_link_map set approved_p = 't' where link_id = :link_id"

}

db_release_unused_handles

ad_returnredirect $return_url

