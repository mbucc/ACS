# $Id: password-update-2.tcl,v 3.0.4.1 2000/04/28 15:11:24 carsten Exp $
set_the_usual_form_variables

# password_1, password_2, password_old

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect /register/
    return
}

set db [ns_db gethandle]

set exception_text ""
set exception_count 0

set password_query "select password 
from users 
where user_id = $user_id
and user_state = 'authorized'"

set dbpasswd [database_to_tcl_string_or_null $db $password_query]

if {[ad_parameter EncryptPasswordsInDBP "" 0]} {
    if {[ns_crypt $password_old [ad_crypt_salt]] == $dbpasswd}  {
	set old_pwd_match_p 1
    } else {
	set old_pwd_match_p 0
    }
} else {
    if {$password_old == $dbpasswd}  {
	set old_pwd_match_p 1
    } else {
	set old_pwd_match_p 0
    }
}

if {!$old_pwd_match_p } {
    append exception_text "<li>Your current password does not match what you entered in the form\n"
    incr exception_count
}


if { ![info exists password_1] || [empty_string_p $password_1] } {
    append exception_text "<li>You need to type in a password\n"
    incr exception_count
}

if { ![info exists password_2] || [empty_string_p $password_2] } {
    append exception_text "<li>You need to confirm the password that you typed.  (Type the same thing again.) \n"
    incr exception_count
}


if { [string compare $password_2 $password_1] != 0 } {
    append exception_text "<li>Your passwords don't match!  Presumably, you made a typo while entering one of them.\n"
    incr exception_count
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# If we are encrypting passwords in the database, do it now.
if {[ad_parameter EncryptPasswordsInDBP "" 0]} { 
    set QQpassword_1 [philg_quote_double_quotes [ns_crypt $password_1 [ad_crypt_salt]]]
}

set sql "update users set password = '$QQpassword_1' where user_id = $user_id"

if [catch { ns_db dml $db $sql } errmsg] {
    ad_return_error "Ouch!"  "The database choked on our update:
<blockquote>
$errmsg
</blockquote>
"
} else {
    ns_return 200 text/html "[ad_header "Password Updated"]

<h2>Password Updated</h2>

in [ad_site_home_link]

<hr>

You can return to [ad_pvt_home_link]

[ad_footer]
"
}

