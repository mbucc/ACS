# $Id: set-on-vacation-until.tcl,v 3.1 2000/03/10 01:45:04 mbryzek Exp $

if [catch { ns_dbformvalue [ns_conn form] on_vacation_until date on_vacation_until } errmsg] {
    ad_return_error "Invalid date" "AOLserver didn't like the date that you entered."
    return
}

set user_id [ad_get_user_id]

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

# We update the users table to maintain compatibility with acs installations prior to user_vacations
ns_db dml $db "update users set on_vacation_until = '$on_vacation_until' where user_id = $user_id"

ns_db dml $db "insert into user_vacations
(vacation_id, user_id, start_date, end_date, receive_email_p, vacation_type)
values 
(user_vacations_vacation_id_seq.nextVal, $user_id, sysdate, '$on_vacation_until', 'f', 'vacation')"

ns_db dml $db "end transaction"

ns_db releasehandle $db

ReturnHeaders

ns_write "[ad_header "Vacation Information Updated"]

<h2>Vacation Information Updated</h2>

in [ad_site_home_link]

<hr>

You won't get any email until after [util_AnsiDatetoPrettyDate $on_vacation_until].

<p>

Please return to [ad_pvt_home_link].

[ad_footer]
"
