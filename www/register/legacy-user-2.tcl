# $Id: legacy-user-2.tcl,v 3.1.4.2 2000/04/28 15:11:25 carsten Exp $
set_the_usual_form_variables

# user_id, password1, password2, maybe return_url

set exception_count 0
set exception_text ""

if { ![info exists password1] || [empty_string_p $password1] } {
    incr exception_count
    append exception_text "<li>Please type the same password in both boxes.\n"
}

if { ![info exists password2] || [empty_string_p $password2] } {
    incr exception_count
    append exception_text "<li>Please type the same password in both boxes.\n"
}

if { [info exists password1] && [info exists password2] && ([string compare $password1 $password2] != 0) } {
    incr exception_count
    append exception_text "<li>The passwords you typed didn't match.  Please type the same password in both boxes.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set db [ns_db gethandle]

# for security, we are only willing to update rows where converted_p = 't'
# this keeps people from hijacking accounts

validate_integer "user_id" $user_id

ns_db dml $db "update users 
set password = '$QQpassword1',
    converted_p = 'f'
where user_id = $user_id
and converted_p = 't'"

if ![info exists return_url] {
    set return_url [ad_pvt_home]
}

ad_user_login $db $user_id
ad_returnredirect $return_url
#ad_returnredirect "/cookie-chain.tcl?cookie_name=[ns_urlencode ad_auth]&cookie_value=[ad_encode_id $user_id $password1]&final_page=[ns_urlencode $return_url]"


