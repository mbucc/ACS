# File:     /homepage/rmnh-1.tcl

ad_page_contract {
    Page to delete a neighborhood.

    @param neighborhood_node System variable to get us back where we started
    @param dir_node Node to delete

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Thu Jan 27 02:21:55 EST 2000
    @cvs-id rmnh-1.tcl,v 3.2.2.10 2000/07/21 04:00:46 ron Exp
} {
    neighborhood_node:notnull,naturalnum
    dir_node:notnull,naturalnum
}

# ------------------------------ initialization codeBlock ----

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

# ------------------------ initialDatabaseQuery codeBlock ----

# Checking for site-wide administration status
set admin_p [ad_administrator_p $user_id]

if {$admin_p == 0} {
    ad_returnredirect "dialog-class?title=Access Management&text=Unable to delete the neighborhood you requested.<br>Insufficient permission to perform requested database access in DeleteNeighborhood.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
    
}

set delete_sql "
delete from users_neighborhoods
where neighborhood_id=:dir_node
"

db_dml delete_neighborhood $delete_sql

# And off with the handle!
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect neighborhoods?neighborhood_node=$neighborhood_node

