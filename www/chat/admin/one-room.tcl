# /www/chat/admin/one-room.tcl

ad_page_contract {
    Display information of this chat room.

    @param chat_room_id The chat room id

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chat_room_id chat room to display
    @creation-date 18 November 1998
    @cvs-id one-room.tcl,v 1.5.2.10 2000/09/22 01:37:14 kevin Exp
} {
    {chat_room_id:naturalnum,notnull}
}


if { [db_string chat_admin_chat_room_counts {select count(*) from chat_rooms where chat_room_id = :chat_room_id}] == 0 } {
    ad_return_error "Not Found" "Could not find chat_room $chat_room_id"
    return
}

db_1row chat_admin_select_one_chat_room {
    select pretty_name, scope, group_id, expiration_days, active_p, moderated_p
    from chat_rooms
    where chat_room_id = :chat_room_id }

ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

if { $scope=="group" } {
    set short_name [db_string chat_admin_one_room_get_group_short_name "select short_name
                                                from user_groups
                                                where group_id = :group_id"]    
}

if { $scope == "public" } {
    set userpage_url_string "/chat/enter-room.tcl?chat_room_id=$chat_room_id&scope=$scope"
} else {
#    set userpage_url_string "/groups/$short_name/chat/chat.tcl?chat_room_id=$chat_room_id&scope=$scope&group_id=$group_id" 
    set userpage_url_string "/chat/enter-room.tcl?chat_room_id=$chat_room_id&scope=$scope&group_id=$group_id" 
}

set page_content "

[ad_scope_admin_header "$pretty_name"]
[ad_scope_admin_page_title $pretty_name]
[ad_scope_admin_context_bar [list "index.tcl" Chat] "One Room"]

<hr>

User page:  <a href=\"$userpage_url_string\">$userpage_url_string</a>

"

if [empty_string_p $expiration_days] {
    set n_expired_msgs 0
    set expired_select_item ""
} else {
    set expired_select_item ", sum(decode(sign((sysdate-$expiration_days)-creation_date),1,1,0)) as n_expired_msgs"
}

db_1row chat_admin_select_some_room_stuff "select min(creation_date) as min_date, max(creation_date) as max_date, count(*) as n_messages, count(distinct creation_user) as n_users $expired_select_item
from chat_msgs
where chat_room_id = :chat_room_id" 

append page_content "
<ul>
<li>oldest message:  $min_date
<li>newest message:  $max_date
<li>total messages: $n_messages (from $n_users distinct users)
</ul>

<h3>Properties</h3>

<form action=\"edit-room\" method=post>
[export_form_scope_vars chat_room_id]
<table>
<tr>
    <td align=right>Room Name:</td>
    <td><input name=pretty_name size=35 value=\"[philg_quote_double_quotes $pretty_name]\"></td>
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
    <option value=t selected>Moderated</option>
    "
} else {
    append page_content "
    <option value=f selected>Unmoderated</option>
    <option value=t>Moderated</option>
    "
}

append page_content "
</select>
</td>
<tr><td></td><td><input type=submit value=Update></td></tr>
</table>
</form>

"

if { $n_expired_msgs > 0 } {
    append page_content "<li> <a href=expire-messages?[export_url_scope_vars chat_room_id]>Deleted expired messages</a> ($n_expired_msgs)\n"
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
<br>
"

append page_content "<ul>
<li> <a href=delete-messages?[export_url_scope_vars chat_room_id]>Delete all messages from this room</a>

<li><a href=delete-room?[export_url_scope_vars chat_room_id]>Delete this room</a>
</ul>

[ad_scope_admin_footer]
"



doc_return  200 text/html $page_content












