# $Id: set-on-vacation-to-null.tcl,v 3.1 2000/03/10 01:45:04 mbryzek Exp $
set user_id [ad_get_user_id]

set db [ns_db gethandle]

set on_vacation_until [database_to_tcl_string_or_null $db \
	"select on_vacation_until from users where user_id = $user_id"]

if { ![empty_string_p $on_vacation_until] } {
    ns_db dml $db "begin transaction"

    ns_db dml $db "delete from user_vacations 
where user_id=$user_id 
and to_char(end_date,'YYYY-MM-DD')='$on_vacation_until'"

    ns_db dml $db "update users set on_vacation_until = NULL where user_id = $user_id"

    ns_db dml $db "end transaction"
}

ns_db releasehandle $db

ReturnHeaders

ns_write "[ad_header "Vacation Information Updated"]

<h2>Vacation Information Updated</h2>

in [ad_site_home_link]

<hr>

You're marked as back from vacation.

<p>

Please return to [ad_pvt_home_link].

[ad_footer]
"
