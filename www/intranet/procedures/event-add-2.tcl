# /www/intranet/procedures/event-add-2.tcl

ad_page_contract {
    Records a procedure event (Certification of another user for the
    procedure)

    @param procedure_id the id of the procedure we're looking at
    @param user_id user_id for whom we're recording the event
    @param note general notes about recording this event
    @param event_date date of the event
    @param event_id  sequence-generated identifier for im_procedure_events

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id event-add-2.tcl,v 3.3.2.9 2001/01/12 17:00:09 khy Exp
} {
    procedure_id:integer,notnull
    user_id:integer,optional
    note
    event_date:array,date,optional
    event_id:integer,notnull,verify
}

set supervising_user [ad_maybe_redirect_for_registration]

if {[db_string user_verify "select count(*) from im_procedure_users where user_id = :supervising_user and procedure_id = :procedure_id"] == 0} {
    ad_return_error "Error" "You're not allowed to certify new users"
    return
}

set exception_count 0
set exception_text ""

if {![info exists user_id] || [empty_string_p $user_id]} {
    incr exception_count
    append exception_text "<LI>Missing name of user to certify\n"
}
if { [info exists event_date(date)] } { 
    set e_date $event_date(date)
} else {
    incr exception_count
    append exception_text "<LI>Error with date entered.  Please reenter date."
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

db_dml update_event "update im_procedure_events 
set note = :note, user_id = :user_id, procedure_id = :procedure_id, 
    event_date = :e_date, supervising_user = :supervising_user
where event_id = :event_id"

#if the previous update didn't modify any rows, insert a new row with the data
if {[db_resultrows] == 0} {
    db_dml create_event "insert into im_procedure_events
(event_id, user_id, procedure_id, note, supervising_user, event_date) values
(:event_id, :user_id, :procedure_id, :note, :supervising_user, :e_date)"
}

db_release_unused_handles

ad_returnredirect info?[export_url_vars procedure_id]



