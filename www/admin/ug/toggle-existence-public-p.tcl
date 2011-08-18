# $Id: toggle-existence-public-p.tcl,v 3.0.4.1 2000/04/28 15:09:35 carsten Exp $
set_the_usual_form_variables

# group_id

set db [ns_db gethandle]

ns_db dml $db "update user_groups set existence_public_p = logical_negation(existence_public_p) where group_id = $group_id"

ad_returnredirect "group.tcl?group_id=$group_id"

