# /www/groups/group/index.tcl

ad_page_contract {
    Purpose: this is the group public page
    Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
    group_vars_set contains group related variables (group_id, group_name, group_short_name,
    group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
    group_type_url_p, group_context_bar_list and group_navbar_list)

    @author Contact: teadams@arsdigita.com, tarik@arsdigita.com
    @creation-date  mid-1998

    @cvs-id index.tcl,v 3.7.2.8 2000/10/25 19:47:44 kevin Exp
} {
    
}

set user_id [ad_get_user_id]

set group_name [ns_set get $group_vars_set group_name]
set group_public_url [ns_set get $group_vars_set group_public_url]
set group_admin_url [ns_set get $group_vars_set group_admin_url]


db_1row "group_get_ug_info" "
select ug.approved_p, ug.creation_user, ug.registration_date, ug.group_type, 
 ug.new_member_policy, u.first_names, u.last_name 
 from user_groups ug, users u 
 where group_id = :group_id 
 and ug.creation_user = u.user_id"



if { $approved_p == "f" } {
    doc_return  200 text/html "
    [ad_scope_header "Main Page"]
    [ad_scope_page_title "Main Page"]
    [ad_scope_context_bar_ws_or_index $group_name] 
    <hr>
    <blockquote>
    <font color=red>this group is awaiting approval by [ad_system_owner]</font>
    </blockquote>
    [ad_scope_footer]
    "
    return
}

append page_top "
[ad_scope_header "Main Page"]
[ad_scope_page_title "Main Page"]
[ad_scope_context_bar_ws_or_index $group_name] 
<hr>
"

if { [ad_user_group_authorized_admin $user_id $group_id] && ![empty_string_p $group_admin_url] } {
    append page_top [help_upper_right_menu [list "$group_admin_url/" "Administration Page"]]
}

append page_top "<blockquote><h4>Preferences</h4>"

set is_member_p 0
if { $user_id == 0 } {
    if { $new_member_policy != "closed" } {
	# there is at least some possibility of a member joining
	append html "If you want to join this group, you'll need to <a href=\"/register?return_url=[ad_urlencode "$group_public_url/member-add"]\">log in </a>."
    }
} else {
    # the user is logged in
    if { [string compare [db_string group_get_user_group_ids "select ad_group_member_p (:user_id, :group_id) from dual"] "t"] == 0 } {
	# user is already a member
	set is_member_p 1

	append page_top "You are a member of this group.  You can <a href=\"member-remove\">remove yourself</a>."

	# Get current spam setting and allow the user to change it.
    
	set counter [db_string group_count_email_prefs {
	    select count (*) 
	    from group_member_email_preferences 
	    where group_id = :group_id 
	    and user_id = :user_id}]

	if { $counter == 0 } {
	    set dont_spam_me_p f
	} else {
	    set dont_spam_me_p [db_string select_dont_spam_me_p {
		select dont_spam_me_p 
		from group_member_email_preferences 
		where group_id = :group_id 
		and user_id = :user_id}] 
	}
    
    append page_top "<br>Email settings:
    <font size=-1>
    [ad_choice_bar [list "Receive Group Emails" "Don't Spam Me" ]\
	 [list "edit-preference?dont_spam_me_p=f&return_url=index" \
               "edit-preference?dont_spam_me_p=t&return_url=index"] \
         [list "f" "t"]  $dont_spam_me_p]
    </font>"

} else {
	switch $new_member_policy {
	    "open"  { 
		append page_top "
		This group has an open enrollment policy.  You can simply
		<a href=\"member-add\">sign up</a>."
	    }
	    "wait"  {
		append page_top "
		The administrator approves users who wish to join this group.
		<a href=\"member-add\">Submit your name for approval</a>."
	    }
	    "closed" {
		append page_top "
		This group has closed membership policy. You cannot become a member of this group."
	    }
	} 
    }
}

append page_top "</blockquote>"

set page_body $page_top

# get group sections 
set query_sql {
    select section_key, section_pretty_name, section_type, section_id 
    from content_sections 
    where scope = 'group' 
    and group_id = :group_id 
    and (section_type = 'static' or 
    section_type = 'custom' or 
    (section_type = 'system' and module_key! = 'custom-sections')) 
    and enabled_p = 't' 
    order by sort_key 
}

set system_section_counter 0
set non_system_section_counter 0
db_foreach select_query $query_sql {

    if { [string compare $section_type system]==0 } {
    
	append system_sections_html "
	<a href=[ad_urlencode $section_key]/>$section_pretty_name</a><br>
	"    
	incr system_section_counter
    } else {
	append non_system_sections_html "
	<a href=[ad_urlencode $section_key]/?section_id=$section_id>$section_pretty_name</a><br>
	"    
	incr non_system_section_counter
    }

}

append system_sections_html "
<a href=\"spam-index\">Email to the Group</a><br>
"
incr system_section_counter

if { [expr $system_section_counter + $non_system_section_counter]>0 } {
    append html "
    <h4>Sections</h4>
    "
    
    if { $system_section_counter>0 } {
	append html "
	$system_sections_html
	"
    }

    if { $non_system_section_counter>0 } {
	append html "
	<br>
	$non_system_sections_html
	"
    }
}

# let's look for administrators

set query_sql {
    select u.user_id as admin_user_id, u.first_names || ' ' || u.last_name as name 
    from user_group_map ugm, users u 
    where ugm.user_id = u.user_id 
    and ugm.group_id = :group_id 
    and ugm.role = 'administrator' 
}

# This query used to be:
#
# "select user_id as admin_user_id, first_names || ' ' || last_name as name
# from users 
# where ad_user_has_role_p ( user_id, $group_id, 'administrator' ) = 't'"]

db_foreach select_query $query_sql {
    append administrator_items "<a href=\"/shared/community-member?user_id=$admin_user_id\">$name</a><br>\n"
}

if [info exists administrator_items] {
    append html "<h4>Group Administrators</h4>\n\n$administrator_items\n"
}

db_release_unused_handles

append page_body "
<blockquote>
$html
</blockquote>
[ad_style_bodynote "Created by <a href=\"/shared/community-member?user_id=$creation_user\">$first_names $last_name</a> on [util_AnsiDatetoPrettyDate $registration_date]"]
[ad_scope_footer]
"

doc_return 200 text/html $page_body
