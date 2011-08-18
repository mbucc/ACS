# $Id: banned-user.tcl,v 3.1 2000/03/10 22:21:45 lars Exp $
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

if { $user_state == "banned" } {
    ns_return 200 text/html "[ad_header "Sorry"]

<h2>Sorry</h2>

<hr>

Sorry but it seems that you've been banned from [ad_system_name].

[ad_footer]
"
    return
} else {
    ad_return_error "Problem with user authentication" "You have encountered a problem with authentication"
}
