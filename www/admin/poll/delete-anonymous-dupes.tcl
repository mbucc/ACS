# $Id: delete-anonymous-dupes.tcl,v 3.0.4.1 2000/04/28 15:09:14 carsten Exp $
# delete-anonymous-dupes.tcl
#
# by philg@mit.edu on October 25, 1999
#
# deletes anonymous duplicate votes from the same IP address

set_the_usual_form_variables

# poll_id, deletion_threshold (if there are this many or more, nuke 'em)

if { $deletion_threshold == 1 } {
    ad_return_complaint 1 "<li>you picked a threshold of 1; this would mean that you'd delete ALL the anonymous votes!"
    return
}

set db [ns_db gethandle] 

ns_db dml $db "delete from poll_user_choices
where poll_id = $poll_id 
and user_id is null
and (choice_id, ip_address) in 
    (select choice_id, ip_address
     from poll_user_choices
     where user_id is null
     group by choice_id, ip_address
     having count(*) >= $deletion_threshold)"

ad_returnredirect "integrity-stats.tcl?[export_url_vars poll_id]"
