ad_page_contract {

    A page to send deleted users to.
    
    @cvs-id deleted-user.tcl,v 3.2.6.6 2000/09/22 01:39:14 kevin Exp
} { 
    user_id:naturalnum
}

if { ![db_0or1row register_deleted_user_state {
    select user_state from users where user_id = :user_id
}] } {

    ad_return_error "Couldn't find your record" "User id $user_id is not in the database.  This is probably our programming bug."
    return
}

db_release_unused_handles

if { $user_state == "deleted" } {
    # they presumably deleted themselves

    doc_return  200 text/html "[ad_header "Welcome Back"]

    <h2>Welcome Back</h2>
    
    to [ad_site_home_link]
    
    <hr>
    
    Your account is currently marked \"deleted\". If you wish, we
    can <a href=\"restore-user?user_id=$user_id\">restore your account
    to live status</a>.
    
    [ad_footer]
    "
} else {
    ad_return_error "Problem with authentication" "You have encountered a problem with authentication"
}