# $Id: joinnh.tcl,v 3.0.4.1 2000/04/28 15:11:01 carsten Exp $
# File:     /homepage/joinnh.tcl
# Date:     Thu Jan 27 09:09:43 EST 2000
# Location: 42Å∞21'N 71Å∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Lets you join a neighbourhood

set_form_variables
# neighborhood_node, nid

# First, we need to get the user_id
set user_id [ad_verify_and_get_user_id]

# If the user is not registered, we need to redirect him for
# registration
if { $user_id == 0 } {
    ad_redirect_for_registration
    return
}

set db [ns_db gethandle]

if {![info exists nid] || [empty_string_p $nid]} {
    set nid null
}

ns_db dml $db "
update users_homepages
set neighborhood_id = $nid
where user_id = $user_id
"

# And let's go back to the main maintenance page
ad_returnredirect neighborhoods.tcl?neighborhood_node=$neighborhood_node
