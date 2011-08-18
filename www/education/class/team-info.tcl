#
# /www/education/class/team-info.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this page displays info about a given team
#

ad_page_variables {
    team_id
}


set db [ns_db gethandle]

set id_list [edu_user_security_check $db]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]


set exception_count 0
set exception_text ""


if {[empty_string_p $team_id]} {
    incr exception_count
    append exception_text "<li>You must provide a team number."
} else {
    set selection [ns_db 0or1row $db "select
                     team_name,
                     class_name,
                     edu_current_classes.class_id
                from edu_teams,
                     edu_current_classes
               where team_id = $team_id
                 and edu_current_classes.class_id = edu_teams.class_id
                 and edu_teams.class_id = $class_id"]

    if {$selection == ""} {
	incr exception_count
	append exception_text "The team number that you have requested does not exist or access to this page has been restricted by the class administrator and you are not authorized."
    } else {
	set_variables_after_query
    }
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set return_string "
[ad_header "View Team for $class_name @ [ad_system_name]"]
<h2>$team_name</h2>
Part of $class_name
<p>
[ad_context_bar_ws_or_index [list "" "All Classes"] [list "one.tcl" "$class_name Home"] [list "teams-view.tcl?class_id=$class_id" "View Teams"] "One Team"]

<hr>

<blockquote>

<h3>Team Members</h3>
<ul>
"

# if the current user is a team member or someone in the class
# with "Spam Users" permissions

set spam_user_permission_p [ad_permission_p $db "" "" "Spam Users" $user_id $class_id]

set selection [ns_db select $db "select users.user_id as student_id, 
             first_names || ' ' || last_name as student_name,
             url as student_url 
        from edu_teams, 
             user_group_map map, 
             users 
       where team_id = map.group_id 
         and map.user_id = users.user_id
         and team_id = $team_id
     order by last_name"]


set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if {[empty_string_p $student_url]} {
	append return_string "<li>$student_name"
    } else {
	append return_string "<li><a href=\"$student_url\">$student_name</a>"
    }
    incr count

    # if they are a member of the team, let them spam the team
    if {$student_id == $user_id} {
	set spam_user_permission_p 1
    }
}

set show_spam_link_p 1

if {$count == 0} {
    append return_string "There are not currently any students assigned to this team."
    set show_spam_link_p 0
}

if {$spam_user_permission_p && $show_spam_link_p} {
    append return_string "<p><a href=\"spam.tcl?who_to_spam=member&subgroup_id=$team_id\">Spam Team Members</a>"
}


append return_string "
</ul>

<h4>Status Reports</h4>
<ul>
"


set comment_permission_p [database_to_tcl_string_or_null $db "select 1 from users, 
        user_group_map ug_map
  where users.user_id = $user_id 
    and ug_map.group_id = $team_id
    and users.user_id = ug_map.user_id"]

if {[empty_string_p $comment_permission_p]} {
    set comment_permission_p [ad_permission_p $db "" "" "View Admin Pages" $user_id $class_id]
}

if {$comment_permission_p == 1} {
    set progress_reports [ad_general_comments_list $db $team_id EDU_TEAM_INFO $team_name]
} else {
    set progress_reports "[ad_general_comments_summary_sorted $db $team_id EDU_TEAM_INFO $team_name]"
}

if {[string compare $progress_reports "<ul></ul>"] == 0} {
    append return_string "No status reports available"
} else {
    append return_string "$progress_reports"
}


append return_string "
</ul>
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string







