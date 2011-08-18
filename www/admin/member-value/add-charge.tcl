# $Id: add-charge.tcl,v 3.0.4.1 2000/04/28 15:09:10 carsten Exp $
set_the_usual_form_variables

# note: nobody gets to this page who isn't a site administrator (ensured
# by a filter in ad-security.tcl)

# user_id (the guy who will be charged), charge_type
# amount, charge_comment

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_return_error "no filter" "something wrong with the filter on add-charge.tcl; couldn't find registered user_id"
    return
}

set db [ns_db gethandle]
ns_db dml $db "insert into users_charges (user_id, admin_id, charge_type, amount, charge_comment, entry_date)
values
($user_id, $admin_id, '$QQcharge_type', $amount, '$QQcharge_comment', sysdate)"

ad_returnredirect "user-charges.tcl?user_id=$user_id"

