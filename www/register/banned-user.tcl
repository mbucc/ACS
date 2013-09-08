ad_page_contract {
    
    Page to send banned users when they login.
    @cvs-id banned-user.tcl,v 3.1.12.6 2000/09/22 01:39:14 kevin Exp
} {
    user_id:naturalnum
}

# Verify that the user is in the banned state
if { ![db_0or1row register_banned_user_state {
    select user_state from users 
    where user_id = :user_id }
      ]} {
    ad_return_error "Couldn't find your record" "User id $user_id is not in the database.  This is probably our programming bug."
    return
}

if { ![string equal $user_state "banned"] } {
    ad_return_error "Problem with user authentication" "You have encountered a problem with authentication"
    return
}

# User is truely banned
db_release_unused_handles


doc_return  200 text/html "
[ad_header "Sorry"]

<h2>Sorry</h2>

<hr>

Sorry but it seems that you've been banned from [ad_system_name].

[ad_footer]
"