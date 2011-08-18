# $Id: group-shortname-edit-2.tcl,v 3.0.4.1 2000/04/28 15:09:32 carsten Exp $
#
# group-shortname-edit-2.tcl
#
# actually updates the short_name column in the user_groups table
#

set_the_usual_form_variables

# group_id, short_name

if [empty_string_p $QQshort_name] {
    ad_return_complaint 1 "<li>you shouldn't change shortname of a group to the empty string!  Please type a shortname."
    return
}

set db [ns_db gethandle]

ns_db dml $db "update user_groups 
set short_name = '$QQshort_name'
where group_id = $group_id"

ad_returnredirect "group.tcl?group_id=$group_id"

