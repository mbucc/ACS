# /admin/links/restore.tcl

ad_page_contract {
    Restores a link to "live" status if it has been erroneously kicked into "dead" or "removed" for whatever reason

    @param page_id The ID of the page the link is on
    @param url The URL of the link

    @author Philip Greenspun (philg@mit.edu)
    @creation-date July 18, 1999
    @cvs-id restore.tcl,v 3.2.2.5 2000/07/24 18:23:30 ryanlee Exp
} {
    page_id:notnull,naturalnum
    url:notnull
}

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}

# we know who the administrator is

db_dml update_link_to_live "update links 
set status = 'live'
where page_id = :page_id
and url = :url"

db_release_unused_handles

ad_returnredirect "one-page?[export_url_vars page_id]"
