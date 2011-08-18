#
# /www/education/class/admin/teams/edit-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page updates the groups table to relect the new team name
#

ad_page_variables {
    team_id
    team_name
}

if {[empty_string_p $team_name]} {
    ad_return_complaint 1 "<li>You must provide a new name for this team."
    return
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


# lets ensure that this team is part of this class

if {[database_to_tcl_string $db "select count(team_id) from edu_teams where team_id = $team_id and class_id = $class_id"] == 0} {
    ad_return_complaint 1 "<li>The team that you are trying to edit does not belong to $class_name."
    return
}

ns_db dml $db "update user_groups set group_name = [ns_dbquotevalue $team_name] where group_id = $team_id"

ns_db releasehandle $db

ad_returnredirect "one.tcl?team_id=$team_id"