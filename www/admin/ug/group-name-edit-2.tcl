# $Id: group-name-edit-2.tcl,v 3.0.4.1 2000/04/28 15:09:30 carsten Exp $
#
# group-name-edit-2.tcl
#
# actually updates the group_name column in the user_groups table
#

set_the_usual_form_variables

# group_id, group_name

if [empty_string_p $QQgroup_name] {
    ad_return_complaint 1 "<li>you shouldn't rename a group to the empty string!  Please type a name."
    return
}

set db [ns_db gethandle]

ns_db dml $db "update user_groups 
set group_name = '$QQgroup_name'
where group_id = $group_id"

ad_returnredirect "group.tcl?group_id=$group_id"

