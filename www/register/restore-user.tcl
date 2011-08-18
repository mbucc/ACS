# $Id: restore-user.tcl,v 3.0 2000/02/06 03:54:05 ron Exp $
set_the_usual_form_variables

# user_id



set db [ns_db gethandle] 

set selection [ns_db 0or1row $db "select user_state, email from users where user_id = $user_id"]

# The page restores a user from the deleted state.
# This page is sensitive to security holes because it is based on a user_id

if { $selection == "" } {
    ad_return_error "Couldn't find your record" "User id $user_id is not in the database.  This is probably out programming bug."
    return
}

set_variables_after_query

if { $user_state == "deleted" } {

    # they presumably deleted themselves
    
    # Note that the only transition allowed if from deleted
    # to authorized.  No other states may be restored

ns_db dml $db "update users set user_state = 'authorized'  
where user_id = $user_id"

ns_return 200 text/html "[ad_header "Restored"]

<h2>Your Account is Restored</h2>

at [ad_site_home_link]

<hr>

Your account has been restored.  You can log in now using your old
password:

<p>

<form action=\"user-login-2.tcl\" method=post>
[export_form_vars user_id]
Password:  <input type=password name=password_from_form size=20>
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