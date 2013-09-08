# File: /admin/general-links/toggle-assoc-approved-p.tcl

ad_page_contract {
    Toggles approval of link association.

    @param map_id The link association to toggle.
    @param approved_p Set the link association's new approval status to this.
    @param return_url Where to go when finished toggling.

    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @creation-date 2/01/2000
    @cvs-id toggle-assoc-approved-p.tcl,v 3.2.6.6 2000/07/24 18:25:16 ryanlee Exp
} {
    map_id:notnull,naturalnum
    approved_p:notnull
    {return_url "view-associations?link_id=$link_id"}
}

#--------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

db_transaction {

    set link_id [db_string select_link_id {select link_id from site_wide_link_map where map_id = :map_id}]

    db_dml set_approved_p {update site_wide_link_map set approved_p = :approved_p, approval_change_by = :current_user_id where map_id = :map_id}

}

db_release_unused_handles

ad_returnredirect $return_url

