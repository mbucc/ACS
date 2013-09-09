# /www/admin/member-value/add-charge.tcl

ad_page_contract {
    Add a charge to an user.
    
    @param user_id
    @param chage_type
    @param amount
    @param charge_comment    
    @author mbryzek@arsdigita.com
    @creation-date Tue Jul 11 21:02:42 2000
    @cvs-id add-charge.tcl,v 3.2.2.6 2000/08/05 00:41:07 jmp Exp

} {
    user_id:integer,notnull
    charge_type:notnull 
    amount:notnull
    charge_comment:notnull,nohtml
}

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_return_error "no filter" "something wrong with the filter on add-charge; couldn't find registered user_id"
    return
}
 
if {![regexp {^([0-9]+)(\.)?([0-9]*)$} $amount]} {
    ad_return_complaint 1 " <li>Amount must be a positive number."
    return 0
}

db_dml mv_users_charges_insertion "insert into users_charges (user_id, admin_id, charge_type, amount, charge_comment, entry_date)
values
(:user_id, :admin_id, :charge_type, :amount, :charge_comment, sysdate)"

db_release_unused_handles

ad_returnredirect "user-charges?user_id=$user_id"

