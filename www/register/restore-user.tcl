ad_page_contract {
    The page restores a user from the deleted state.
    @cvs-id restore-user.tcl,v 3.2.2.6 2000/09/22 01:39:15 kevin Exp
} {
    user_id:naturalnum
}

if {![db_0or1row user_state_info {
    select user_state, email from users where user_id = :user_id
}]} { 
    ad_return_error "Couldn't find your record" "User id $user_id is not in the database.  This is probably out programming bug."
    return
}

if { $user_state == "deleted" } {
    
    # they presumably deleted themselves  
    # Note that the only transition allowed if from deleted
    # to authorized.  No other states may be restored

    db_dml user_state_authorized_transistion {
	update users 
	set user_state = 'authorized'  
	where user_id = :user_id
    }
    
    doc_return  200 text/html "[ad_header "Restored"]

<h2>Your Account is Restored</h2>

at [ad_site_home_link]

<hr>

Your account has been restored.  You can log in now using your old
password:

<p>

<form action=\"user-login-2\" method=post>
[export_form_vars user_id]
Password:  <input type=password name=password size=20>
<input type=submit value=\"Login\">
</form>

<p>

Note: If you've forgotten your password, <a
href=\"email-password.tcl?user_id=$user_id\">ask this server to email it
to $email</a>.

[ad_footer]
"
} else {
    ad_return_error "Problem with authentication" "There was a problem with authenticating your account"
}