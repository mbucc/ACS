# www/admin/chat/one-room.tcl
ad_page_contract {
    Shows info for one chat room.

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author ahmeds@arsdigita.com
    @param chat_room_id
    @creation-date 18 November 1999
    @creation-date 18 November 1999
    @cvs-id one-room.tcl,v 3.2.2.10 2000/09/22 01:34:29 kevin Exp
} {
    {chat_room_id:naturalnum}
}

# Get group_id immediately since there is no later dependency for its setting.
set group_id [ad_administration_group_id chat $chat_room_id]


if {![db_0or1row admin_chat_get_chat_room_info {
    select chat_room_id,
        pretty_name,
        private_group_id,
	moderated_p,
	expiration_days,
	creation_date,
	active_p,
	scope,
	group_id
    from  chat_rooms 
    where chat_room_id = :chat_room_id
}]} {
    ad_return_error "Not Found" "Could not find chat_room $chat_room_id"
    return
}

if { [string compare $scope "group"] == 0 } {
    set short_name [db_string admin_chat_get_short_group_name {
	select short_name from user_groups where group_id = :group_id
    }]
}

if { [string compare $scope "public"] == 0 } {
    set userpage_url_string "/chat/enter-room.tcl?chat_room_id=$chat_room_id&scope=$scope"
} else {
    set userpage_url_string "/chat/enter-room.tcl?chat_room_id=$chat_room_id&scope=$scope&group_id=$group_id" 
}


set page_content "

[ad_admin_header "$pretty_name"]
<h2>$pretty_name</h2>
[ad_admin_context_bar [list "index.tcl" Chat] "One Room"]

<hr>

User page:  <a href=\"$userpage_url_string\">$userpage_url_string</a>

"

if [empty_string_p $expiration_days] {
    set n_expired_msgs 0
    set expired_select_item ""
} else {
    set expired_select_item ", sum(decode(sign((sysdate-$expiration_days)-creation_date),1,1,0)) as n_expired_msgs"
}

if { ![db_0or1row admin_chat_get_chat_room_usage_stats " 
    select min(creation_date) as min_date, 
           max(creation_date) as max_date, 
           count(*) as n_messages, 
           count(distinct creation_user) as n_users 
           $expired_select_item
    from chat_msgs
    where chat_room_id = :chat_room_id"] } {
        
    append page_content "<ul><i>No chat room usage statistics available.</i></ul>"

} else {
    append page_content "
    <ul>
    <li>Oldest message:  $min_date
    <li>Newest message:  $max_date
    <li>Total messages: $n_messages (from $n_users distinct users)
    </ul> "
}

set group_options_widget [ad_db_optionlist admin_chat_get_all_group_rooms {
    select unique group_name, user_groups.group_id 
    from user_groups, user_group_map 
    where user_groups.group_id=user_group_map.group_id 
    and user_groups.group_type <> 'administration'
    order by group_name
} $group_id]


append page_content "

<h3>Properties</h3>

<form action=\"/admin/chat/edit-room\" method=post>
[export_form_vars chat_room_id]
<table>
<tr>
    <td align=right>Room Name:</td>
    <td><input name=pretty_name size=35 value=\"[philg_quote_double_quotes $pretty_name]\"></td>
</tr>
<tr>
    <td align=right>Group (optional):</td>
    <td>
    <select name=group_id>
    <option value=\"\">No Group, this is a Public Chat Room</option>
    $group_options_widget
    </select></td>
</tr>
<tr>
    <td align=right>Expire messages after</td>
    <td><input type=text name=expiration_days value=\"$expiration_days\" size=4> days (or leave blank to archive messages indefinitely)</td>
</tr>
<tr>
    <td align=right>Active?</td>
    <td><select name=active_p>
"
if {$active_p=="t"} {
    append page_content "
    <option value=f>No</option>
    <option value=t selected>Yes</option>
    "
} else {
    append page_content "
    <option value=f selected>No</option>
    <option value=t>Yes</option>
    "
}

append page_content "
</select>
</td>
</tr>
<tr>
    <td align=right>Moderation Policy:</td>
    <td><select name=moderated_p>
"
if {$moderated_p=="t"} {
    append page_content "
    <option value=f>Unmoderated</option>
    <option value=t selected>Moderated (see below)</option>
    "
} else {
    append page_content "
    <option value=f selected>Unmoderated</option>
    <option value=t>Moderated (see below)</option>
    "
}

append page_content "
</select>
</td>
</tr>
<tr><td></td><td><input type=submit value=Update></td></tr>
</table>
</form>
<h3>Moderators</h3>
"
set group_id [ad_administration_group_id chat $chat_room_id]
set moderators ""
db_foreach admin_chat_get_chat_room_moderators {
    select users.user_id as moderator_id, 
	first_names, 
	last_name
    from users, user_group_map
    where group_id=:group_id 
    and users.user_id = user_group_map.user_id
} {
    lappend moderators "<a href=\"/admin/users/one?user_id=$moderator_id\">$first_names $last_name</a>"
}

set moderators [join $moderators ", "]

if {[empty_string_p $moderators]} {
    set moderators "none"
}

append page_content "
Current Moderator(s):
$moderators

<center>
<form method=GET action=\"/admin/ug/group\">
[export_form_vars group_id]
<input type=submit value=\"Add/Remove Moderators\">
</form>
</center>

<h3>Extreme Actions</h3>
<ul>
"

if { $n_expired_msgs > 0 } {
    append page_content "<li> <a href=expire-messages?[export_url_vars chat_room_id]>Deleted expired messages</a> ($n_expired_msgs)\n"
}

append page_content "
<li> <a href=delete-messages?[export_url_vars chat_room_id]>Delete all messages from this room</a>

<li><a href=delete-room?[export_url_vars chat_room_id]>Delete this room</a>
</ul>

[ad_admin_footer]
"



doc_return  200 text/html $page_content
















