# $Id: email-password.tcl,v 3.3 2000/03/10 22:45:20 lars Exp $
set_the_usual_form_variables

# user_id

if {![ad_parameter EmailForgottenPasswordP "" 1]} {
    ad_return_error "Feature disabled" "This feature is disabled on this server."
    return    
}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select password, email 
from users where user_id=$user_id
and user_state = 'authorized'"]

if { $selection == "" } {
    ns_db releasehandle $db
    ad_return_error "Couldn't find user $user_id" "Couldn't find user $user_id.  This is probably a bug in our code."
    return
}

set_variables_after_query

if {[ad_parameter EmailRandomPasswordWhenForgottenP "" 0] || [ad_parameter EncryptPasswordsInDBP "" 0] } {
    #generate a random password
    set password [ad_generate_random_string]
    if  [ad_parameter EncryptPasswordsInDBP "" 0] {
	# need to encrypt
	set password_for_database [ns_crypt $password [ad_crypt_salt]]
    } else {
	set password_for_database $password
    }
    ns_db dml $db "update users set password = '[DoubleApos $password_for_database]'  where user_id= $user_id"
}

ns_db releasehandle $db


# Send email
if [catch { ns_sendmail $email [ad_system_owner] "Your forgotten password on [ad_system_name]" "Here's how you can log in at [ad_url]:

Username:  $email
Password:  $password

"} errmsg] {
    ad_return_error "Error sending mail" "Now we're really in trouble because we got an error trying to send you email:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    return
}

ns_return 200 text/html "[ad_header "Check Your Inbox"]

<h2>Check Your Inbox</h2>

<hr>

Please check your inbox.  Within the next few minutes, you should find
a message from [ad_system_owner] containing your password.

<p>

Then come back to <a href=\"user-login.tcl?email=$email\">the login
page</a> and use [ad_system_name].


[ad_footer]"
