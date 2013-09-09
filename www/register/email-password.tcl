ad_page_contract {
    Sends the user their password.  Depending on the configuration,
    this password may be a new random password.
    @cvs-id email-password.tcl,v 3.6.2.4 2000/09/22 01:39:14 kevin Exp
} {
    user_id:integer
}


if {![ad_parameter EmailForgottenPasswordP "" 1]} {
    ad_return_error "Feature disabled" "This feature is disabled on this server."
    return    
}


set bind_vars [ad_tcl_vars_to_ns_set user_id]

if ![db_0or1row users_state_authorized_or_deleted "select 
password, email  from users where user_id=:user_id
and user_state in ('authorized','deleted')" -bind $bind_vars] {
    db_release_unused_handles
    ad_return_error "Couldn't find user $user_id" "Couldn't find user $user_id.  This is probably a bug in our code."
    return
}



if {[ad_parameter EmailRandomPasswordWhenForgottenP "" 0] || [ad_parameter EncryptPasswordsInDBP "" 0] } {
    #generate a random password
    set password [ad_generate_random_string]
    if  [ad_parameter EncryptPasswordsInDBP "" 0] {
	# need to encrypt
	set password_for_database [ns_crypt $password [ad_crypt_salt]]
    } else {
	set password_for_database $password
    }
    ns_set put $bind_vars password_for_database $password_for_database

    db_dml user_password_update "update users set password = :password_for_database  where user_id= $user_id" -bind $bind_vars
}

db_release_unused_handles

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

doc_return  200 text/html "[ad_header "Check Your Inbox"]

<h2>Check Your Inbox</h2>

<hr>

Please check your inbox.  Within the next few minutes, you should find
a message from [ad_system_owner] containing your password.

<p>

Then come back to <a href=\"user-login?email=$email\">the login
page</a> and use [ad_system_name].

[ad_footer]"
