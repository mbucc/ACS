#
# /www/education/class/teams-view.tcl
#
# by randyg@arsdigita.com, aileen@arsdigita.com, February 2000
#
# this page lists the teams in the class
#

# this page does not expect any input


set db [ns_db gethandle]

set id_list [edu_user_security_check $db]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]

set selection [ns_db 0or1row $db "select class_name, class_id from edu_current_classes where class_id = $class_id"]

if {$selection == ""} {
    ad_return_complaint 1 "<li>The class identification number that you have provided is not valid either because it is an old class or because access to this page has been restricted by the class administrator."
    return
} else {
    set_variables_after_query
}


set selection [ns_db select $db "
select t.* from edu_teams t
where class_id=$class_id"]

set return_string "
[ad_header "View Teams for $class_name"]

<h2>Teams</h2>

[ad_context_bar_ws_or_index [list "" "All Classes"] [list "one.tcl" "$class_name Home"] "View Teams"]

<hr>

<blockquote>
"

set team_string ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    append team_string "
    <li><a href=\"team-info.tcl?team_id=$team_id\">$team_name</a>
    "
}

if {[empty_string_p $team_string]} {
    append return_string "
    There are no teams for $class_name
    "
} else {
    append return_string "$team_string"
}

append return_string "
<br>
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string






