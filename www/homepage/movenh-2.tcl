#  File:     /homepage/movenh-2.tcl

ad_page_contract {
    Purpose:  Page to move a neighborhood

    @param neighborhood_node The neighborhood one originally came from
    @param move_node The neighborhood to move from
    @param move_target The neighborhood to move to

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Thu Jan 27 02:54:54 EST 2000
    @cvs-id movenh-2.tcl,v 3.2.2.9 2000/07/21 04:00:44 ron Exp
} {
    neighborhood_node:notnull,naturalnum
    move_node:notnull,naturalnum
    move_target:notnull,naturalnum
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
    ad_returnredirect "dialog-class?title=Access Management&text=Unable to move the neighborhood you requested.<br>Insufficient permission to perform requested database access in MoveNeighborhood.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
    
}

set dml_sql "
update users_neighborhoods
set parent_id=:move_target
where neighborhood_id=:move_node
"

db_dml move_neighborhood $dml_sql

# And off with the handle!
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect neighborhoods?neighborhood_node=$neighborhood_node

