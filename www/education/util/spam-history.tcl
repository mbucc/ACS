#
# /www/education/util/spam-history.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# borrows extensivley from /groups/group/spam-history.tcl
#
# this displays the history of spam sent by one user or one group.
#

ad_page_variables {
    {user_id ""}
    {group_id ""}
}

# user_id is the user whose history you wish to view
# either user_id or group_id must be not null
# and the other must be null

if {[empty_string_p $group_id] && [empty_string_p $user_id]} {
    ad_return_complaint 1 "<li>Either group id or user id must be not null"
    return
} elseif {![empty_string_p $group_id] && ![empty_string_p $user_id]} {
    ad_return_complaint 1 "<li>You should only provide a group id or a user id"
    return
}


set db_handles [edu_get_two_db_handles]
set db [lindex $db_handles 0]
set db_sub [lindex $db_handles 1]

set group_pretty_type [edu_get_group_pretty_type_from_url]

# right now, the proc above is only set up to recognize type 
# group and department and the proc must be changed if this page
# is to be used for URLs besides those.

if {[empty_string_p $group_pretty_type]} {
    ns_returnnotfound
    return
} else {

    if {[string compare $group_pretty_type class] == 0} {
	set id_list [edu_user_security_check $db]
    } else {
	# it is a department
	set id_list [edu_group_security_check $db edu_department]
    }
}


set actual_user_id [lindex $id_list 0]
set user_group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]


#
# we want to make sure the user has permission to view this
#

set spam_permission_p [ad_permission_p $db "" "" "Spam Users" $user_id $group_id]

if {!$spam_permission_p} {
    # if user_id is not null and they do not have permission as 
    # specified above then they should only see it if it is themselves
    if {![empty_string_p $user_id]} {
	if {[string compare $user_id $actual_user_id] != 0} {

	}
    } else {
	# user_id is null so group_id is not...we made sure of that above
	# we do not check to see if they are part of the main group because we
	# already know that from the checks above.  And, if they had permission
	# to spam the users, spam_permission_p would already be 1 from the
	# call to ad_permission_p
	
	if {[string compare $group_id $user_group_id] != 0} {
	    if {![database_to_tcl_string $db "select decode(count(user_id),0,0,1) from user_group_map where user_id = $user_id and group_id = $group_id"]} {
		set spam_permission_p 1
	    }
	}
    }
}	


# make sure that the group_id they are trying to view is part of the group
# they are logged in as.

if {![empty_string_p $group_id] && [string compare $group_id $user_group_id] != 0} {
    # make sure that the subgroup is part of this group

    set subgroup_name [database_to_tcl_string $db "select group_name from user_groups where parent_group_id = $user_group_id and group_id = $group_id"]

    if {![empty_string_p $subgroup_name]} {
	set spam_permission_p 1
    }
}


if {!$spam_permission_p} {
    ad_return_complaint 1 "<li>You do not currently have permission to spam the group you are trying to spam."
    return
}


#
# permisisons to view this page have been taken care of
#


if {![empty_string_p $user_id]} {
    set name [database_to_tcl_string_or_null $db "select first_names || ' ' || last_name from users where user_id = $user_id"]
    
    set history_type user

} else {
    # this means that group_id must be not null
    set name [database_to_tcl_string_or_null $db "select group_name from user_groups where group_id = $group_id"]
    set history_type group
}


if {[empty_string_p $name]} {
    ad_return_complaint 1 "<li>The $history_type you have requested is not a member of this group."
    return
}



if {[lsearch [ns_conn urlv] admin] == -1} {
    set nav_bar "[ad_context_bar_ws_or_index [list "one.tcl" "$group_name Home"] "Spam History"]"
    set teams_link "teams/one.tcl"
    set hyperlink_sender_p 0
} else {
    set nav_bar "[ad_context_bar_ws_or_index [list "../one.tcl" "$group_name Home"] [list "" "Administration"] "Spam History"]"
    set teams_link "team-info.tcl"
    set hyperlink_sender_p 1
}


set return_string "
[ad_header "$group_name @ [ad_system_name]"]

<h2>Spam History for $name</h2>

$nav_bar

<hr>

"


if {[empty_string_p $group_id] && ![empty_string_p $user_id]} {
    # the first thing that we need to do is compile a list of groups the user
    # may be sending mail to that are related to this group.  This includes the
    # entire group, the teams, and the sections.  Once we do that, we do the
    # select and then display the information to the user.
    
    set team_list [database_to_tcl_list $db "select team_id from edu_teams where group_id = $group_id"]

    set section_list [database_to_tcl_list $db "select section_id from edu_sections where group_id = $group_id"]

    set group_list [concat [list $group_id] $team_list $section_list]

    set sql_suffix "sender_id = $user_id and user_groups.group_id in ([join $group_list ","])"

} else {
    set sql_suffix "user_groups.group_id = $group_id"
    # lets find out what type of group this is
    set group_type [database_to_tcl_string $db "select group_type from user_groups where group_id = $group_id"]
    if {[string compare $group_type edu_team] == 0} {
	set team_list [list $group_id]
	set section_list [list]
    } elseif {[string compare $group_type edu_section == 0} {
	set team_list [list]
	set section_list [list $group_id]
    }
}


set selection [ns_db select $db "select 
        user_groups.group_id as recipient_group_id,
        group_name,
        group_spam_history.approved_p,
        send_date,
        subject,
        group_spam_history.body,     
        group_spam_history.creation_date,
        n_receivers_intended,
        n_receivers_actual,
        send_to_roles,
        first_names || ' ' || last_name as sender_name,
        sender_id,
        from_address as sender_email,
        spam_id
from group_spam_history, users, user_groups
where $sql_suffix
and sender_id = users.user_id
and user_groups.group_id = group_spam_history.group_id
order by creation_date desc"]


set counter 0

append html "
<table border=1 cellpadding=3>

<tr>
"

if {![empty_string_p $group_id]} {
    append html "<th>From Address</th>"
} else {
    append html "<th>Group Sent To</th>"
}

append html "
<th>Roles Sent To</th>
<th>Subject</th>
<th>Send Date</th>
<th><br>No. of Intended <br> Recipients</th>
<th><br>No. of Actual <br> Recipients</th>
</tr>
"    

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    incr counter
    
    set approved_string [ad_decode $send_date "" "N/A" $send_date]

    set subject [ad_decode $subject "" None $subject]

    if {$group_id == $user_group_id} {
	set spam_group_table edu_classes
    } elseif {[lsearch $team_list $recipient_group_id] > -1} {
	set spam_group_table edu_teams
	set url_to_send_to "$teams_link?team_id=$recipient_group_id"
    } else {
	set spam_group_table edu_sections
	set url_to_send_to "section-info.tcl?section_id=$recipient_group_id"
    }

    append html "
    <tr>
    "

    if {![empty_string_p $group_id]} {
	if {$hyperlink_sender_p} {
	    append html "<td><a href=\"users/one.tcl?user_id=$sender_id\">$sender_name</a><Br> ($sender_email)"
	} else {
	    append html "<td>$sender_name<Br> ($sender_email)"
	}
    } else {
	append html "<td><a href=\"$url_to_send_to\">$group_name</a>"
    }	


    set send_to_pretty_roles [list]
    foreach role $send_to_roles {
	set pretty_role_plural "[database_to_tcl_string_or_null $db_sub "select pretty_role_plural from edu_role_pretty_role_map where lower(role) = lower('$role') and group_id = $group_id"]"
	if {![empty_string_p $pretty_role_plural]} {
	    lappend send_to_pretty_roles $pretty_role_plural
	} else {
	    lappend send_to_pretty_roles "[capitalize $role]s"
	}
    }
    
    set send_to_pretty_roles [join $send_to_pretty_roles ", "]


    append html "
    <td align=center>[ad_decode $send_to_roles "" "N/A" $send_to_pretty_roles]</td>
    <td align=center><a href=\"spam-item.tcl?[export_url_vars spam_id spam_group_table]\">$subject</a>
    <td align=center>$creation_date
    <td align=center>$n_receivers_intended
    <td align=center>$n_receivers_actual
    </tr>
    "
}

if { $counter > 0 } {
    append html "</table>" 
} else {
    set html "No Email history of $name for $group_name group available in the database."
}



append return_string "
<blockquote>
$html
</blockquote>
<p><br>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string




