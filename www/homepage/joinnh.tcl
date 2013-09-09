# File:     /homepage/joinnh.tcl
ad_page_contract {
    Lets you join a neighbourhood.

    @param nid The neighborhood ID to join
    @param neighborhood_node The neighborhood ID to return to when done

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Thu Jan 27 09:09:43 EST 2000
    @cvs-id joinnh.tcl,v 3.1.6.9 2000/07/21 04:00:42 ron Exp
} {
    neighborhood_node:notnull,naturalnum
    {nid:notnull,naturalnum {[db_null]}}
}

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

db_dml update_user_neighborhood "
 update users_homepages
 set neighborhood_id = :nid
 where user_id = :user_id
"

# Release unwanted handles
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect neighborhoods?neighborhood_node=$neighborhood_node









