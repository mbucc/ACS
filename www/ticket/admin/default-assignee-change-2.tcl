# /www/ticket/admin/default-assignee-change-2.tcl
ad_page_contract {
    Assigns passed in user id to the project and domain

    @param user_id_from_search the lucky guy or gal
    @param domain_id the ID of the assigned domain
    @param project_id the ID of the assigned project
    @param ticket_return
    @param return_url where to go next

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date 15 May 2000
    @cvs-id default-assignee-change-2.tcl,v 3.1.6.4 2000/07/21 04:04:37 ron Exp
} {
    user_id_from_search:integer,notnull
    domain_id:integer,notnull
    project_id:integer,notnull
    { ticket_return "" }
    { return_url "" } 
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

db_dml assignee_update "
update ticket_domain_project_map 
set default_assignee = :user_id_from_search
where project_id = :project_id
and domain_id = :domain_id" 

db_release_unused_handles

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect index.tcl?view=project&[export_url_vars project_id ticket_return]
}




