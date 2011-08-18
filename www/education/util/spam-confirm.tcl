#
# /www/education/util/spam-confirm.tcl
#
# modified from /groups/group/spam-confirm.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page confirms that you want to send the email that you have just typed in
#


ad_page_variables {
    subject
    who_to_spam
    header
    message
    from_address
    {subgroup_id ""}
}

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


set sender_id [lindex $id_list 0]
set group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]


# lets make sure that they have permission to spam this group
set spam_permission_p [ad_permission_p $db "" "" "Spam Users" $sender_id $group_id]

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
        where user_id = $sender_id 
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


#
# now, the security is taken care of
#


if {[empty_string_p $message]} {
    ad_return_complaint 1 "<li>You must provide a message for this email."
    return
}

if {[lsearch [ns_conn urlv] admin] == -1} {
    set nav_bar "[ad_context_bar_ws_or_index [list "one.tcl" "$group_name Home"] "Confirm Spam"]"
} else {
    set nav_bar "[ad_context_bar_ws_or_index [list "../one.tcl" "$group_name Home"] [list "" "Administration"] "Confirm Spam"]"
}


set return_string "
[ad_header "$group_name Administration @ [ad_system_name]"]

<h2>Spam $header</h2>

$nav_bar

<hr>
<blockquote>

"

set creation_date [database_to_tcl_string $db "select to_char(sysdate, 'YYYY-MM-DD  HH:MI:SS am') from dual"]

set spam_roles [list]

foreach role $who_to_spam {
    lappend spam_roles "'[string tolower $role]'"
}

if {![empty_string_p $subgroup_id]} {
    set group_id $subgroup_id
}

set n_recipients [database_to_tcl_string $db "
    select count(distinct ug.user_id)
    from user_group_map ug, users_spammable u
	where ug.group_id = $group_id
        and lower(ug.role) in ([join $spam_roles ","])
	and ug.user_id = u.user_id
	and not exists ( select 1 
	                 from group_member_email_preferences
                         where group_id = $group_id
	                 and user_id =  u.user_id 
                         and dont_spam_me_p = 't')
        and not exists ( select 1 
	                 from user_user_bozo_filter
                         where origin_user_id = u.user_id 
	                 and target_user_id =  $sender_id)"]
 

# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [database_to_tcl_string $db "select group_spam_id_sequence.nextval from dual"]


ns_db releasehandle $db

append return_string "

<form method=POST action=\"spam-send.tcl\">
[export_form_vars who_to_spam spam_id from_address subject message n_recipients header spam_roles group_id]

<blockquote>

<table border=0 cellpadding=5 >

<tr><th align=right>Date</th><td>$creation_date </td></tr>

<tr><th align=right>To </th><td>$header of $group_name</td></tr>
<tr><th align=right>From </th><td>$from_address</td></tr>


<tr><th align=right>Subject </th><td>$subject</td></tr>

<tr><th align=right valign=top>Message </th><td>
<pre>[ns_quotehtml $message]</pre>
</td></tr>

<tr><th align=right>Number of recipients </th><td>$n_recipients</td></tr>

</table>

</blockquote>
"

if {$n_recipients == 0} {
    append return_string "No one will receive this email since there is no one in the selected group."
} else {
    append return_string "<center><input type=submit value=\"Send Email\"></center>"
}

append return_string "
</blockquote>
[ad_footer]
"

ns_return 200 text/html $return_string




