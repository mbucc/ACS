# $Id: delete-2.tcl,v 3.0.4.1 2000/04/28 15:09:36 carsten Exp $
set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/"]
    return
}

set_the_usual_form_variables

# user_id, optional banned_p, banning_note
# return_url (optional)

set db [ns_db gethandle]

set user_name [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = $user_id"]


if { [info exists banned_p] && $banned_p == "t" } {
    ns_db dml $db "update users 
set banning_user = $admin_user_id,
    banned_date = sysdate,
    banning_note = '$QQbanning_note',
    user_state = 'banned'
where user_id = $user_id"
    set action_report "has been banned."
} else {
    ns_db dml $db "update users set deleted_date=sysdate,
deleting_user = $admin_user_id,
user_state = 'deleted'
where user_id = $user_id"
    set action_report "has been marked \"deleted\"."
}

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
    return
}

ns_return 200 text/html "[ad_admin_header "Account deleted"]

<h2>Account Deleted</h2>

<hr>

$user_name $action_report.

[ad_admin_footer]
"
