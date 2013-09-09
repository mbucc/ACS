# File:     /homepage/rename-2.tcl

ad_page_contract {
    Page to rename a file

    @param neighborhood_node System variable to get us to the start
    @param rename_node ID of file to rename
    @param new_name New name for file
    @param new_desc New description for file

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Wed Jan 19 02:21:25 EST 2000
    @cvs-id renamenh-2.tcl,v 3.2.2.9 2000/07/21 04:00:46 ron Exp
} {
    neighborhood_node:notnull,naturalnum
    rename_node:notnull,naturalnum
    new_name:notnull,trim
    new_desc:notnull,trim
}

# --------------------------- initialErrorCheck codeBlock ----

set exception_count 0
set exception_text ""

#  if { ![info exists new_name] || [empty_string_p $new_name] } {
#      ad_returnredirect "dialog-class?title=Neighborhood Management&text=Unable to rename the requested neighborhood.<br>New name not provided.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
#      return
#  }

if {[regexp {.*/.*} $new_name match]} {
    ad_returnredirect "dialog-class?title=Neighborhood Management&text=Unable to rename the requested neighborhoods.<br>This operation is not for moving neighborhoods.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
}

if {[regexp {.*\.\..*} $new_name match]} {
    ad_returnredirect "dialog-class?title=Neighborhood Management&text=Unable to rename the requested neighborhood.<br>This operation is not for moving neighborhoods.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
}

if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
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

set nh_exists_p [db_string select_nh_exists_p "
select count(*)
from users_neighborhoods
where neighborhood_name=:new_name
and parent_id=:neighborhood_node
and neighborhood_id != :rename_node"]

if {$nh_exists_p != 0} {
    ad_returnredirect "dialog-class?title=Neighborhood Management&text=Unable to rename neighborhood you requested.<br>A Neighborhood with that name already exists.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return

}

if {$admin_p == 0} {
    ad_returnredirect "dialog-class?title=Access Management&text=Unable to rename the neighborhood you requested.<br>Insufficient permission to perform requested database access in RenameNeighborhood.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
    
}

set dml_sql "
update users_neighborhoods
set neighborhood_name=:new_name,
description=:new_desc
where neighborhood_id=:rename_node
"
db_dml update_neighborhood_name $dml_sql

# And off with the handle!
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect neighborhoods?neighborhood_node=$neighborhood_node
