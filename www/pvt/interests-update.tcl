# $Id: interests-update.tcl,v 3.0.4.1 2000/04/28 15:11:24 carsten Exp $
set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

if { [ns_getform] == "" } {
    set category_id_list [list]
} else {
    set category_id_list [util_GetCheckboxValues [ns_getform] category_id [list]]
}

ns_db dml $db "begin transaction"
ns_db dml $db "delete from users_interests where user_id = $user_id"
foreach category_id $category_id_list {
    ns_db dml $db "insert into users_interests
(user_id, category_id, interest_date) 
values
($user_id, $category_id, sysdate)"
}
ns_db dml $db "end transaction"

ad_returnredirect "home.tcl"
