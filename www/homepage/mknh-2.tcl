# $Id: mknh-2.tcl,v 3.1.4.1 2000/04/28 15:11:02 carsten Exp $
# File:     /homepage/mkdir-2.tcl
# Date:     Fri Jan 14 18:48:26 EST 2000
# Location: 42ÅÅ∞21'N 71ÅÅ∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to create a Neighborhood

set_the_usual_form_variables
# neighborhood_node, nh_name, nh_desc

# --------------------------- initialErrorCheck codeBlock ----

set exception_count 0
set exception_text ""

# Recover if having the urge to elbow out dialog-class
#if { ![info exists nh_name] || [empty_string_p $nh_name] } {
#    incr exception_count
#    append exception_text "
#    <li>You did not specify a name for the Neighborhood."
#}

if { ![info exists neighborhood_node] || [empty_string_p $neighborhood_node] } {
    ad_return_error "Neighborhood Node Information Missing"
}

if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}

if { ![info exists nh_name] || [empty_string_p $nh_name] } {
    ad_returnredirect "dialog-class.tcl?title=Neighborhood Management&text=Unable to create the new neighborhood you requested.<br>You did not provide a name for it.&btn1=Okay&btn1target=neighborhoods.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
}

if { ![info exists nh_desc] || [empty_string_p $nh_desc] } {
    ad_returnredirect "dialog-class.tcl?title=Neighborhood Management&text=Unable to create the new neighborhood you requested.<br>You did not provide a description for it.&btn1=Okay&btn1target=neighborhoods.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
}

if {[regexp {.*/.*} $nh_name match]} {
    ad_returnredirect "dialog-class.tcl?title=Access Management&text=Unable to create the requested Neighborhood.<br>Attempted to access some other directory.&btn1=Okay&btn1target=neighborhoods.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
}

if {[regexp {.*\.\..*} $nh_name match]} {
    ad_returnredirect "dialog-class.tcl?title=Access Management&text=Unable to create the requested Neighborhood.<br>Tried to access parent directory.&btn1=Okay&btn1target=neighborhoods.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node"
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

# The database handle (a thoroughly useless comment)
set db [ns_db gethandle]

# Checking for site-wide administration status
set admin_p [ad_administrator_p $db $user_id]

set nh_exists_p [database_to_tcl_string $db "
select count(*)
from users_neighborhoods
where neighborhood_name='$QQnh_name'
and parent_id=$neighborhood_node"]

if {$nh_exists_p != 0} {
    ad_returnredirect "dialog-class.tcl?title=Neighborhood Management&text=Unable to create the new neighborhood you requested.<br>A Neighborhood with that name already exists.&btn1=Okay&btn1target=neighborhoods.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return

#    ad_return_error "Unable to Create Neighborhood" "Sorry, the Neighborhood name you requested already exists."
#    return
}

if {$admin_p == 0} {
    ad_returnredirect "dialog-class.tcl?title=Access Management&text=Unable to create the new neighborhood you requested.<br>Insufficient permission to perform requested database access in AddNeighborhood.&btn1=Okay&btn1target=neighborhoods.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node"
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
'$QQnh_name', 
'$QQnh_desc',
$neighborhood_node)"

ns_db dml $db $dml_sql


# And off with the handle!
ns_db releasehandle $db

# And let's go back to the main maintenance page
ad_returnredirect neighborhoods.tcl?neighborhood_node=$neighborhood_node
