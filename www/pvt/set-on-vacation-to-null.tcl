now using [db_null]# /www/pvt/set-on-vacation-to-null.tcl
ad_page_contract {
    Set on vacation to null.

    @author Multipe
    @cvs-id set-on-vacation-to-null.tcl,v 3.1.12.6 2000/09/22 01:39:11 kevin Exp
} 

set user_id [ad_get_user_id]

set on_vacation_until [db_string on_vacation_until {
    select on_vacation_until from users where user_id = :user_id
} -default ""] 

if { ![empty_string_p $on_vacation_until] } {
    db_transaction {

	db_dml pvt_delete_user_vacation {
	    delete from user_vacations 
	    where user_id=:user_id 
	    and to_char(end_date,'YYYY-MM-DD') = :on_vacation_until
	} 

	db_dml pvt_unset_on_vacation {
	    update users 
	    set on_vacation_until = [db_null] 
	    where user_id = :user_id
	}
    }
}

doc_return  200 text/html
 "
[ad_header "Vacation Information Updated"]

<h2>Vacation Information Updated</h2>

in [ad_site_home_link]

<hr>

You're marked as back from vacation.

<p>

Please return to [ad_pvt_home_link].

[ad_footer]
"
