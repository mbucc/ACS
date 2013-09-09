# File: /admin/general-links/toggle-link-approved-p.tcl

ad_page_contract {
    Toggles approval of a link.

    @param link_id The link to toggle.
    @param return_url Where to go when finished toggling.
    @param approved_p Set the link's new approval status to this.

    @author Tzu-Mainn Chen (tzumainn@arsdigita.com)
    @creation-date 2/01/2000
    @cvs-id toggle-link-approved-p.tcl,v 3.2.6.6 2000/07/24 17:27:36 ryanlee Exp
} {
    link_id:notnull,naturalnum
    {return_url "index"}
    approved_p:notnull
}

#--------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

db_dml update_link_approved_p {update general_links set approved_p = :approved_p, last_approval_change = sysdate, approval_change_by = :current_user_id where link_id = :link_id}

db_release_unused_handles

ad_returnredirect $return_url

