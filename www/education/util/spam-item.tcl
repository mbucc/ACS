#
# /www/education/util/spam-item.tcl
#
# started with /groups/group/spam-item.tcl as the base
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page shows one email message corresponding to the passed in
# spam_id
#

ad_page_variables {
    spam_id
    spam_group_table
}

# the spam_id is obvious
# the spam_group_table says whether it was an email to the class, 
# a team, or a section


set db [ns_db gethandle]

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

set user_id [lindex $id_list 0]
set group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]


set exception_text ""
set exception_count 0

if {[empty_string_p $spam_id]} {
    incr exception_count
    append exception_text "<li>No spam id was received."
}

if {[string compare $spam_group_table edu_classes] == 0} {
    set sql_clause "and group_id = class_id and class_id = $group_id"
    set subgroup_name class_name
    set spam_group_id_name class_id
} elseif {[string compare $spam_group_table edu_teams] == 0} {
    set sql_clause "and group_id = team_id and class_id = $group_id"
    set subgroup_name team_name
    set spam_group_id_name team_id
} elseif {[string compare $spam_group_table edu_sections] == 0} {
    set sql_clause "and group_id = section_id and class_id = $group_id"
    set subgroup_name section_name
    set spam_group_id_name section_id
} else {
    incr exception_count
    append exception_text "<li>No spam group table was received. $spam_group_table"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set selection [ns_db 0or1row  $db "select approved_p,
        $subgroup_name as spam_group_name,
        $spam_group_id_name as spam_group_id,
        creation_date,
        first_names || ' ' || last_name as sender_name,
        from_address,
        send_to_roles,
        n_receivers_intended,
        n_receivers_actual,
        subject,
        group_spam_history.body,
        send_date,
        sender_id    
from group_spam_history, $spam_group_table, users
where spam_id = $spam_id
and users.user_id = sender_id
$sql_clause"]


if { [empty_string_p $selection ]} {
    ad_return_complaint 1 "<li>No spam with spam id $spam_id was found in the database."
    return
} else {
    set_variables_after_query
}


# now, lets make sure that the user has permission to view this spam
set spam_permission_p [ad_permission_p $db "" "" "Spam Users" $user_id $group_id]

if {!$spam_permission_p} {
    # are they a member of the group the spam was sent to?
    # if not, tell them they are not allowed to view the spam
    if {[database_to_tcl_string $db "select count(user_id) from user_group_map where group_id = $spam_group_id and user_id = $user_id"] == 0} {
    	ad_return_complaint 1 "<li>You do not currently have permission to spam the group you are trying to spam."
	return
    }
}


set status_string [ad_decode $approved_p "t" "Approved on [util_AnsiDatetoPrettyDate $send_date]" "f" "Disapproved" "Waiting for Approval"]


set send_to_pretty_roles [list]
foreach role $send_to_roles {
    set pretty_role_plural "[database_to_tcl_string_or_null $db "select pretty_role_plural from edu_role_pretty_role_map where lower(role) = lower('$role') and group_id = $group_id"]"
    if {![empty_string_p $pretty_role_plural]} {
	lappend send_to_pretty_roles $pretty_role_plural
    } else {
	lappend send_to_pretty_roles "[capitalize $role]s"
    }
}

ns_db releasehandle $db




set send_to_pretty_roles [join $send_to_pretty_roles ", "]


if {[lsearch [ns_conn urlv] admin] == -1} {
    set nav_bar "[ad_context_bar_ws_or_index [list "one.tcl" "$group_name Home"] "One Email"]"
    set hyperlink_user_p 0
} else {
    set nav_bar "[ad_context_bar_ws_or_index [list "../one.tcl" "$group_name Home"] [list "" "Administration"] "One Email"]"
    set hyperlink_user_p 1
}


set return_string "
[ad_header "$group_name Administration @ [ad_system_name]"]

<h2>One Email</h2>

$nav_bar

<hr>

<blockquote>

<table border=0 cellpadding=3>

<tr><th align=right>Status</th> 
    <td>$status_string
</tr>

<tr><th align=right>Date</th><td>[util_AnsiDatetoPrettyDate $creation_date]</td></tr>

<tr><th align=right>From </th><td>
"

if {$hyperlink_user_p} {
    append return_string "
    <a href=\"users/one.tcl?user_id=$sender_id\">$sender_name</a>
    "
} else {
    append return_string  "$sender_name"
}

append return_string "
($from_address) </td></tr>

<tr><th align=right>To </th><td>$send_to_pretty_roles of $spam_group_name</td></tr>

<tr><th align=right>No. of Intended Recipients </th><td>$n_receivers_intended</td></tr>

<tr><th align=right>No. of Actual Recipients </th><td>$n_receivers_actual</td></tr>

<tr><th align=right>Subject </th><td>$subject</td></tr>

<tr><th align=right valign=top>Message </th><td>
<pre>[ns_quotehtml $body]</pre>
</td></tr>

</table>

</blockquote>

[ad_footer]
"


ns_return 200 text/html $return_string



