# File:     /homepage/mknh-2.tcl

ad_page_contract {
    Page to create a Neighborhood

    @param neighborhood_node System variable to tell us how to get to start
    @param nh_name Name of new neighborhood
    @param nh_desc Description of new neighborhood

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Fri Jan 14 18:48:26 EST 2000
    @cvs-id mknh-2.tcl,v 3.3.2.8 2000/07/21 04:00:44 ron Exp
} {
    neighborhood_node:notnull,naturalnum
    nh_name:notnull,trim
    nh_desc:notnull,trim
}

# --------------------------- initialErrorCheck codeBlock ----


# Recover if having the urge to elbow out dialog-class
# set exception_count 0
# set exception_text ""
#if { ![info exists nh_name] || [empty_string_p $nh_name] } {
#    incr exception_count
#    append exception_text "
#    <li>You did not specify a name for the Neighborhood."
#}

# Obsoleted by new document API
#  if { ![info exists nh_name] || [empty_string_p $nh_name] } {
#      ad_returnredirect "dialog-class?title=Neighborhood Management&text=Unable to create the new neighborhood you requested.<br>You did not provide a name for it.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
#      return
#  }

#  if { ![info exists nh_desc] || [empty_string_p $nh_desc] } {
#      ad_returnredirect "dialog-class?title=Neighborhood Management&text=Unable to create the new neighborhood you requested.<br>You did not provide a description for it.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
#      return
#  }

if {[regexp {.*/.*} $nh_name match]} {
    ad_returnredirect "dialog-class?title=Access Management&text=Unable to create the requested Neighborhood.<br>Attempted to access some other directory.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
}

if {[regexp {.*\.\..*} $nh_name match]} {
    ad_returnredirect "dialog-class?title=Access Management&text=Unable to create the requested Neighborhood.<br>Tried to access parent directory.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
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
where neighborhood_name=:nh_name
and parent_id=:neighborhood_node"]

if {$nh_exists_p != 0} {
    ad_returnredirect "dialog-class?title=Neighborhood Management&text=Unable to create the new neighborhood you requested.<br>A Neighborhood with that name already exists.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return

#    ad_return_error "Unable to Create Neighborhood" "Sorry, the Neighborhood name you requested already exists."
#    return
}

if {$admin_p == 0} {
    ad_returnredirect "dialog-class?title=Access Management&text=Unable to create the new neighborhood you requested.<br>Insufficient permission to perform requested database access in AddNeighborhood.&btn1=Okay&btn1target=neighborhoods&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
    
}

set dml_sql "
insert into users_neighborhoods
(neighborhood_id, 
 neighborhood_name,
 description,  
 parent_id)
values
(users_neighborhood_id_seq.nextval, 
:nh_name, 
:nh_desc,
:neighborhood_node)"

db_dml create_neighborhood $dml_sql

# And off with the handle!
db_release_unused_handles

# And let's go back to the main maintenance page
ad_returnredirect neighborhoods?neighborhood_node=$neighborhood_node
