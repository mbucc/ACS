# $Id: movenh-2.tcl,v 3.0.4.1 2000/04/28 15:11:02 carsten Exp $
# File:     /homepage/movenh-2.tcl
# Date:     Thu Jan 27 02:54:54 EST 2000
# Location: 42°21'N 71°04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Page to move a neighborhood

set_the_usual_form_variables
# neighborhood_node, move_node, move_target

# --------------------------- initialErrorCheck codeBlock ----

set exception_count 0
set exception_text ""

if { ![info exists move_node] || [empty_string_p $move_node] } {
    ad_return_error "Neighborhood Node for move Missing."
    return
}

if { ![info exists move_target] || [empty_string_p $move_target] } {
    ad_return_error "Neighborhood Node for move target Missing."
    return
}

if { ![info exists neighborhood_node] || [empty_string_p $neighborhood_node] } {
    ad_return_error "Neighborhood Node Information Missing"
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

if {$admin_p == 0} {
    ad_returnredirect "dialog-class.tcl?title=Access Management&text=Unable to move the neighborhood you requested.<br>Insufficient permission to perform requested database access in MoveNeighborhood.&btn1=Okay&btn1target=neighborhoods.tcl&btn1keyvalpairs=neighborhood_node $neighborhood_node"
    return
    
}

set dml_sql "
update users_neighborhoods
set parent_id=$move_target
where neighborhood_id=$move_node
"

ns_db dml $db $dml_sql


# And off with the handle!
ns_db releasehandle $db

# And let's go back to the main maintenance page
ad_returnredirect neighborhoods.tcl?neighborhood_node=$neighborhood_node


















