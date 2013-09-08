# /admin/poll/delete-anonymous-dupes.tcl

ad_page_contract {
    Deletes anonymous duplicate votes from the same IP address

    @param poll_id the ID of the poll
    @param deletion_threshold  (if there are this many or more, nuke 'em)

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 25 October 1999
    @cvs-id delete-anonymous-dupes.tcl,v 3.2.2.4 2000/07/21 03:57:51 ron Exp

} {
    poll_id:naturalnum,notnull
    deletion_threshold:naturalnum,notnull 
}

if { $deletion_threshold == 1 } {
    ad_return_complaint 1 "<li>you picked a threshold of 1; this would mean that you'd delete ALL the anonymous votes!"
    return
}


db_dml delete_excess_choices "delete from poll_user_choices
where poll_id = :poll_id 
and user_id is null
and (choice_id, ip_address) in 
    (select choice_id, ip_address
     from poll_user_choices
     where user_id is null
     group by choice_id, ip_address
     having count(*) >= :deletion_threshold)"

db_release_unused_handles

ad_returnredirect "integrity-stats?[export_url_vars poll_id]"
