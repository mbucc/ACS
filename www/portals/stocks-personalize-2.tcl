# symbols, num_indices (optional) market_index<n>, where num_indices is the number of 
# market indices we're allowing the user to choose by checkbox on the previous page

set_the_usual_form_variables

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

set stocks_list [split [remove_whitespace $symbols] ","]

ns_db dml $db "delete from portal_stocks where user_id=$user_id"

foreach stock $stocks_list {
    if {$stock!=""} {
	ns_db dml $db "insert into portal_stocks (symbol, user_id) values ('$stock', $user_id)" 
    }
}

set count 1

while {$count<=$num_indices} {
    if {[info exists market_index${count}]} {
	ns_db dml $db "insert into portal_stocks (symbol, user_id, default_p) values ('[set market_index${count}]', $user_id, 't')"
    }
    incr count
}

ad_returnredirect /portals/user$user_id-1.ptl
