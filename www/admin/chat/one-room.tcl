# $Id: one-room.tcl,v 3.0 2000/02/06 03:10:10 ron Exp $
# File:     admin/chat/one-room.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  shows one chat room

set_the_usual_form_variables

# chat_room_id 

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select * from chat_rooms where chat_room_id = $chat_room_id"]

if { $selection == "" } {
    ad_return_error "Not Found" "Could not find chat_room $chat_room_id"
    return
}

set_variables_after_query

set selection [ns_db 1row $db "
select scope, group_id
from chat_rooms
where chat_room_id = $chat_room_id "]

set_variables_after_query

if { $scope=="group" } {
    set short_name [database_to_tcl_string $db "select short_name
                                                from user_groups
                                                where group_id = $group_id"]    
}

if { $scope == "public" } {
    set userpage_url_string "/chat/chat.tcl?chat_room_id=$chat_room_id&scope=$scope"
} else {
    set userpage_url_string "/groups/$short_name/chat/chat.tcl?chat_room_id=$chat_room_id&scope=$scope&group_id=$group_id" 
}


ReturnHeaders 

ns_write "

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

set selection [ns_db 1row $db "select min(creation_date) as min_date, max(creation_date) as max_date, count(*) as n_messages, count(distinct creation_user) as n_users $expired_select_item
from chat_msgs
where chat_room_id = $chat_room_id"]

set_variables_after_query

ns_write "
<ul>
<li>oldest message:  $min_date
<li>newest message:  $max_date
<li>total messages: $n_messages (from $n_users distinct users)
</ul>

<h3>Properties</h3>

<form action=\"/admin/chat/edit-room.tcl\" method=post>
[export_form_vars chat_room_id]
<table>
<tr>
    <td align=right>Room Name:</td>
    <td><input name=pretty_name size=35 value=\"[philg_quote_double_quotes $pretty_name]\"></td>
</tr>
<tr>
    <td align=right>Group (optional):</td>
    <td><select name=group_id>
<option value=\"\">No Group, this is a Public Chat Room</option>
[ad_db_optionlist $db "select unique group_name, user_groups.group_id 
from user_groups, user_group_map 
where user_groups.group_id=user_group_map.group_id 
and user_groups.group_type <> 'administration'
order by group_name" $group_id]
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
    ns_write "
    <option value=f>No</option>
    <option value=t selected>Yes</option>
    "
} else {
    ns_write "
    <option value=f selected>No</option>
    <option value=t>Yes</option>
    "
}

ns_write "
</select>
</td>
</tr>
<tr>
    <td align=right>Moderation Policy:</td>
    <td><select name=moderated_p>
"
if {$moderated_p=="t"} {
    ns_write "
    <option value=f>Unmoderated</option>
    <option value=t selected>Moderated (see below)</option>
    "
} else {
    ns_write "
    <option value=f selected>Unmoderated</option>
    <option value=t>Moderated (see below)</option>
    "
}
ns_write "
</select>
</td>
</tr>
<tr><td></td><td><input type=submit value=Update></td></tr>
</table>
</form>
<h3>Moderators</h3>
"

set group_id [ad_administration_group_id $db chat $chat_room_id]
set selection [ns_db select $db "select users.user_id as moderator_id, first_names, last_name
from users, user_group_map
where group_id=$group_id 
and users.user_id = user_group_map.user_id"]

set moderators ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    lappend moderators "<a href=\"/admin/users/one.tcl?user_id=$moderator_id\">$first_names $last_name</a>"
}

set moderators [join $moderators ", "]

if {[empty_string_p $moderators]} {
    set moderators "none"
}

ns_write "
Current Moderator(s):
$moderators

<center>
<form method=GET action=\"/admin/ug/group.tcl\">
[export_form_vars group_id]
<input type=submit value=\"Add/Remove Moderators\">
</form>
</center>

<h3>Extreme Actions</h3>
<ul>
"

if { $n_expired_msgs > 0 } {
    ns_write "<li> <a href=expire-messages.tcl?[export_url_vars chat_room_id]>Deleted expired messages</a> ($n_expired_msgs)\n"
}

ns_write "
<li> <a href=delete-messages.tcl?[export_url_vars chat_room_id]>Delete all messages from this room</a>

<li><a href=delete-room.tcl?[export_url_vars chat_room_id]>Delete this room</a>
</ul>

[ad_admin_footer]
"
