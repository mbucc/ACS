# $Id: renamenh-2.tcl,v 3.0.4.1 2000/04/28 15:11:03 carsten Exp $
# File:     /homepage/rename-2.tcl
# Date:     Wed Jan 19 02:21:25 EST 2000
# Location: 42Å∞21'N 71Å∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to rename a file

set_the_usual_form_variables
# neighborhood_node, rename_node, new_name, new_desc

# --------------------------- initialErrorCheck codeBlock ----

set exception_count 0
set exception_text ""

if { ![info exists rename_node] || [empty_string_p $rename_node] } {
    ad_return_error "Neighborhood Target Node for rename Missing."
    return
}

if { ![info exists neighborhood_node] || [empty_string_p $neighborhood_node] } {
    ad_return_error "Neighborhood Node Information Missing"
    return
}

if { ![info exists new_name] || [empty_string_p $new_name] } {
    ad_returnredirect "dialog-class.tcl?title=Neighborhood Management&text=Unable to rename the requested neighborhood.<br>New name not provided.&btn1=Okay&btn1target=neighborhoods.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
}

if {[regexp {.*/.*} $new_name match]} {
    ad_returnredirect "dialog-class.tcl?title=Neighborhood Management&text=Unable to rename the requested neighborhoods.<br>This operation is not for moving neighborhoods.&btn1=Okay&btn1target=neighborhoods.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
}

if {[regexp {.*\.\..*} $new_name match]} {
    ad_returnredirect "dialog-class.tcl?title=Neighborhood Management&text=Unable to rename the requested neighborhood.<br>This operation is not for moving neighborhoods.&btn1=Okay&btn1target=neighborhoods.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node"
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

# The database handle (a thoroughly useless comment)
set db [ns_db gethandle]

# Checking for site-wide administration status
set admin_p [ad_administrator_p $db $user_id]

set nh_exists_p [database_to_tcl_string $db "
select count(*)
from users_neighborhoods
where neighborhood_name='$QQnew_name'
and parent_id=$neighborhood_node
and neighborhood_id != $rename_node"]

if {$nh_exists_p != 0} {
    ad_returnredirect "dialog-class.tcl?title=Neighborhood Management&text=Unable to rename neighborhood you requested.<br>A Neighborhood with that name already exists.&btn1=Okay&btn1target=neighborhoods.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return

}

if {$admin_p == 0} {
    ad_returnredirect "dialog-class.tcl?title=Access Management&text=Unable to rename the neighborhood you requested.<br>Insufficient permission to perform requested database access in RenameNeighborhood.&btn1=Okay&btn1target=neighborhoods.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
    
}


set dml_sql "
update users_neighborhoods
set neighborhood_name='$QQnew_name',
description='$QQnew_desc'
where neighborhood_id=$rename_node
"
ns_db dml $db $dml_sql


# And off with the handle!
ns_db releasehandle $db

# And let's go back to the main maintenance page
ad_returnredirect neighborhoods.tcl?neighborhood_node=$neighborhood_node
