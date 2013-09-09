# set-on-vacation-until.tcl
ad_page_contract {
    Set someone as being on vacation till a give date.
    NOTE: on_vacation_util is expected as a date parameter, but
    ad_page_contract doesn't know how to handle that.

    @author
    @creation-date
    @cvs-id set-on-vacation-until.tcl,v 3.1.12.5 2000/09/22 01:39:11 kevin Exp
} {
}
# 

if [catch { ns_dbformvalue [ns_getform] on_vacation_until date on_vacation_until } errmsg] {
    ad_return_error "Invalid date" "AOLserver didn't like the date that you entered."
    return
}

set user_id [ad_get_user_id]

db_transaction {
    # We update the users table to maintain compatibility with acs installations prior to user_vacations
    set bind_vars [ad_tcl_vars_to_ns_set user_id on_vacation_until]
    db_dml pvt_set_vacation_update "update users set on_vacation_until = :on_vacation_until where user_id = :user_id" -bind $bind_vars

    db_dml pvt_set_vacation_insert_log "insert into user_vacations
(vacation_id, user_id, start_date, end_date, receive_email_p, vacation_type)
values 
(user_vacations_vacation_id_seq.nextVal, :user_id, sysdate, :on_vacation_until, 'f', 'vacation')" -bind $bind_vars

}



doc_return  200 "text/html" "[ad_header "Vacation Information Updated"]

<h2>Vacation Information Updated</h2>

in [ad_site_home_link]

<hr>

You won't get any email until after [util_AnsiDatetoPrettyDate $on_vacation_until].

<p>

Please return to [ad_pvt_home_link].

[ad_footer]
"
