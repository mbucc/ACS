# $Id: deleted-user.tcl,v 3.1 2000/03/10 22:22:28 lars Exp $
set_the_usual_form_variables

# user_id

set db [ns_db gethandle] 
set selection [ns_db 0or1row $db "select user_state from users where user_id = $user_id"]

if { $selection == "" } {
    ad_return_error "Couldn't find your record" "User id $user_id is not in the database.  This is probably our programming bug."
    return
}

set_variables_after_query

ns_db releasehandle $db

if { $user_state == "deleted" } {
# they presumably deleted themselves

ns_return 200 text/html "[ad_header "Welcome Back"]

<h2>Welcome Back</h2>

to [ad_site_home_link]

<hr>

Your account is currently marked \"deleted\". If you wish, we
can <a href=\"restore-user.tcl?user_id=$user_id\">restore your account
to live status</a>.

[ad_footer]
"
} else {
    ad_return_error "Problem with authentication" "You have encountered a problem with authentication"
}