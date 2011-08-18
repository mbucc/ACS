# $Id: user-subscription-classify.tcl,v 3.0.4.1 2000/04/28 15:09:10 carsten Exp $
set_the_usual_form_variables

# user_id, subscriber_class

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_return_error "no filter" "something wrong with the filter on add-charge.tcl; couldn't find registered user_id"
    return
}

set db [ns_db gethandle]

if { [database_to_tcl_string $db "select count(*) from users_payment where user_id = $user_id"] == 0 } {
    ns_db dml $db "insert into users_payment (user_id, subscriber_class) values ($user_id, '$QQsubscriber_class')"
} else {
    ns_db dml $db "update users_payment set subscriber_class = '$QQsubscriber_class' where user_id = $user_id"
}

ad_returnredirect "user-subscription.tcl?user_id=$user_id"
