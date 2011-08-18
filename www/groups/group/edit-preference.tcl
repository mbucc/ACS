# $Id: edit-preference.tcl,v 3.0.4.2 2000/04/28 15:11:00 carsten Exp $
set_the_usual_form_variables 0
# dont_spam_me_p, maybe return_url
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

if { ![exists_and_not_null dont_spam_me_p] } {
    ad_return_complaint 1 "<li>Please specify a value for dont_spam_me_p."
}

if { ![exists_and_not_null return_url] } {
    set return_url "spam-index.tcl"
}

set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id $db]

ad_scope_authorize $db $scope all group_member none

set counter [database_to_tcl_string  $db "
select count(*) 
from group_member_email_preferences
where group_id = $group_id
and user_id = $user_id "]

if { $counter == 0 } {
    ns_db dml $db "insert into group_member_email_preferences
    (group_id, user_id, dont_spam_me_p)
    values 
    ($group_id, $user_id, '$dont_spam_me_p')"
} else {
    ns_db dml $db "update group_member_email_preferences
    set dont_spam_me_p = '$dont_spam_me_p'
    where group_id=$group_id
    and user_id=$user_id"
}

ad_returnredirect $return_url
