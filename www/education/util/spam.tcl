#
# /www/education/util/spam.tcl
# 
# taken from /groups/group/spam.tcl
#
# modified extensively by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
#

ad_page_variables {
    who_to_spam
    {subgroup_id ""}
}

# who_to_spam should be a list of roles of people in this group we wish to spam.
# an example would be [list ta professor] or [list ta professor student]

# subgroup_id designates that we are spamming a subgroup of the class (e.g. a team or
# a section) and it is the group_id of the subgroup we are spamming


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

# lets make sure that they have permission to spam this group
set spam_permission_p [ad_permission_p $db "" "" "Spam Users" $user_id $group_id]

if {!$spam_permission_p} {
    # we do not check to see if they are part of the main group because we
    # already know that from the checks above.  And, if they had permission
    # to spam the users, spam_permission_p would already be 1 from the
    # call to ad_permission_p

    # lets see if they are a member of the subgroup
    if {![empty_string_p $subgroup_id]} {
	set spam_permission_p [database_to_tcl_string $db "select 
              decode(count(user_id),0,0,1) 
         from user_groups 
        where user_id = $user_id 
          and group_id = $subgroup_id"]
    }

    if {!$spam_permission_p} {
	ad_return_complaint 1 "<li>You do not currently have permission to spam the group you are trying to spam."
	return
    }
}	

#
# if they have gotten past this point, they have the correct permissions,
# assuming that the subgroup is part of the group.  We check that now
#

if {![empty_string_p $subgroup_id]} {
    # make sure that the subgroup is part of this group

    set subgroup_name [database_to_tcl_string $db "select group_name from user_groups where parent_group_id = $group_id and group_id = $subgroup_id"]

    if {[empty_string_p $subgroup_name]} {
	ad_return_complaint 1 "<li>You do not currently have permission to spam the group you are trying to spam."
	return
    }

    set header_suffix " of $subgroup_name"
} else {
    set header_suffix ""
}


if {[lsearch [ns_conn urlv] admin] == -1} {
    set nav_bar "[ad_context_bar_ws_or_index [list "one.tcl" "$group_name Home"] Spam]"
} else {
    set nav_bar "[ad_context_bar_ws_or_index [list "../one.tcl" "$group_name Home"] [list "" "Administration"] Spam]"
}


# this will always return a row because we are getting the user_id out of the cookie
set selection [ns_db 1row $db "select first_names || ' ' || last_name as sender_name, email as sender_email from users where user_id = $user_id"]

set_variables_after_query

set header [list]

foreach role $who_to_spam {
    set pretty_role_plural "[database_to_tcl_string_or_null $db "select pretty_role_plural from edu_role_pretty_role_map where lower(role) = lower('$role') and group_id = $group_id"]"
    if {![empty_string_p $pretty_role_plural]} {
	lappend header $pretty_role_plural
    } else {
	lappend header "[capitalize $role]s"
    }
}


ns_db releasehandle $db

set header "[join $header ", "] $header_suffix"

ns_return 200 text/html "
[ad_header "$group_name @ [ad_system_name]"]

<h2>Spam $header</h2>

$nav_bar

<hr>
<blockquote>


<form method=POST action=\"spam-confirm.tcl\">
[export_form_vars who_to_spam header subgroup_id]
<table>

<tr><th align=left>From:</th>
<td><input name=from_address type=text size=25 value=\"$sender_email\"></td></tr>

<tr><th align=left>Subject:</th><td><input name=subject type=text size=40></td></tr>

<tr><th align=left valign=top>Message:</th><td>
<textarea name=message rows=10 cols=50 wrap=hard></textarea>
</td></tr>

</table>

<center>
<p>
<input type=submit value=\"Proceed\">

</center>

</form>
<p>

</blockquote>

[ad_footer]
"











