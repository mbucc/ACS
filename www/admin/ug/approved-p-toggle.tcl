# $Id: approved-p-toggle.tcl,v 3.0.4.1 2000/04/28 15:09:25 carsten Exp $
set_the_usual_form_variables

# group_id

set db [ns_db gethandle]

ns_db dml $db "update user_groups set approved_p = logical_negation(approved_p) where group_id = $group_id"

ad_returnredirect "group.tcl?group_id=$group_id"

