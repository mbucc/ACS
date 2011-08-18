# /press/admin/delete-2.tcl
# 
# Author: ron@arsdigita.com, December 1999
#
# (cleaned up by philg@mit.edu, January 7, 2000)
#
# Delete an existing press item
#
# $Id: delete-2.tcl,v 3.0.4.3 2000/04/28 15:11:19 carsten Exp $
# -----------------------------------------------------------------------------

ad_page_variables {press_id}

set user_id  [ad_verify_and_get_user_id]
set db       [ns_db gethandle]

# Get the group restrictions for this press item

set group_id [database_to_tcl_string $db "
select group_id 
from   press 
where  press_id = $press_id"]

# Verify that this user is authorized to do the deletion

if {![press_admin_p $db $user_id $group_id]} {
    ad_return_complaint 1 "<li>Sorry but you're not authorized to
    delete an item of this scope." 
    return
}

# Delete this press item and redirect to the admin page

ns_db dml $db "delete from press where press_id=$press_id"

ad_returnredirect ""
