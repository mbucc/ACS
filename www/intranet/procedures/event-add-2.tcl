# $Id: event-add-2.tcl,v 3.0.4.2 2000/04/28 15:11:10 carsten Exp $
# File: /www/intranet/procedures/event-add-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Records a procedure event (Certification of another user for 
#  the procedure)
#

set_the_usual_form_variables
# procedure_id, user_id, note, event_date

set supervising_user [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

if {[database_to_tcl_string $db "select count(*) from im_procedure_users where user_id = $supervising_user and procedure_id = $procedure_id"] == 0} {
    ad_return_error "Error" "You're not allowed to certify new users"
    return
}

set exception_count 0
set exception_text ""

if {![info exists user_id] || [empty_string_p $user_id]} {
    incr exception_count
    append exception_text "<LI>Missing name of user to certify\n"
}
if [catch {ns_dbformvalue [ns_conn form] event_date date event_date}] {
    incr exception_count
    append exception_text "<LI>The date you entered isn't valid"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

ns_db dml $db "update im_procedure_events 
set note = '$QQnote', user_id = $user_id, procedure_id = $procedure_id, 
    event_date = '$event_date', supervising_user = $supervising_user
where event_id = $event_id"

if {[ns_ora resultrows $db] == 0} {
    ns_db dml $db "insert into im_procedure_events
(event_id, user_id, procedure_id, note, supervising_user, event_date) values
($event_id, $user_id, $procedure_id,'$QQnote', $supervising_user, '$event_date')"
}

ad_returnredirect index.tcl?[export_url_vars procedure_id]
