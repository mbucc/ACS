#
# /www/education/class/admin/teams/index.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This lists all of the teams in the class with some information about each
#

# this does not expect to receive anything

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set return_string "
[ad_header "View Teams for $class_name"]
<h2>$class_name Teams</h2>
[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] "Teams"]

<hr>

<blockquote>
"


set selection [ns_db select $db "
    select count(distinct user_id) as n_members,
           team_name,
           team_id
      from edu_teams,
           user_group_map
     where team_id = group_id(+)
       and class_id = $class_id
   group by team_name, team_id"]


set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    if {!$count} {
	append return_string "
	<table border=1 cellpadding=2>
	<tr>
	<td>Team Name</td>
	<td>Size of Team</td>
	<td>&nbsp;</td>
	</tr>"
    }

    append return_string "
    <tr>
    <td><a href=\"one.tcl?team_id=$team_id\">$team_name</a></td>
    <td align=center>$n_members</td>
    <td><a href=\"evaluation-add.tcl?[export_url_vars team_id]\">Comment</a> |  
    <a href=\"edit.tcl?team_id=$team_id\">Edit</a>"

    if {$n_members > 0} {
	append return_string "
	| <a href=\"spam.tcl?who_to_spam=member&subgroup_id=$team_id\">Spam</a>"
    } 

    append return_string "
    </td>
    </tr>"

    incr count
}

if {$count} {
    append return_string "</table>"
} else {
    append return_string " 
    There are no teams for $class_name<Br>"
}

append return_string "
<br>
<a href=\"create.tcl\">Create a team</a>
</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string






