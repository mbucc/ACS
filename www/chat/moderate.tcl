ad_page_contract {
    This page is for the moderator.

    <b>Note:<b> If the page is accessed through /groups pages then group_id and group_vars_set are already set up in the environment by the ug_serve_section.<br>
    group_vars_set contains group related variables (group_id, group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

    @author Aure (aure@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmeds (ahmeds@arsdigita.com)
    @param chat_room_id
    @param n_rows (has three possible values, "short", "medium", "long"; we do this for caching)
    @param scope
    @param owner_id note that owner_id is the user_id of the user who owns this module (when scope=user)
    @param group_vars_set
    @param on_which_group
    @param on_what_id

    @creation-date 18 November 1998
    @cvs-id moderate.tcl,v 3.5.2.8 2000/09/22 01:37:13 kevin Exp
} {
    chat_room_id:naturalnum,notnull
    n_rows:optional
    scope:optional
    owner_id:optional,naturalnum
    group_vars_set:optional,naturalnum
    on_which_group:optional,naturalnum
    on_what_id:optional,naturalnum

}
# this page will be the most frequently requested in the entire ACS
# it must be super efficient
# it must not query the RDBMS except in unusual cases (e.g., private chat) 

ad_scope_error_check

set user_id [ad_scope_authorize $scope registered group_member none]

if { ![info exists n_rows] || [empty_string_p $n_rows] } {
    set n_rows "short"
}

set private_group_id [chat_room_group_id $chat_room_id]

if { ![empty_string_p $private_group_id] && ![ad_user_group_member_cache $private_group_id $user_id]} {
    ad_returnredirect "bounced-from-private-room.tcl?[export_url_scope_vars chat_room_id]"
    return
}

switch $scope {
    public {
	if { ![ad_administration_group_member chat $chat_room_id $user_id] } {
	    ad_scope_return_error "Not Moderator" "You are not a moderator for this chat room." 
	    return
	}
    }
    group {
	if { ![ad_permission_p "" "" "" $user_id $group_id]==1 } {
	    ad_scope_return_error "Not Moderator" "You are not a moderator for this chat room."
	    return
	}
    }
}

# Get room info
if { ![db_0or1row chat_moderate_get_room_info {
    select pretty_name, moderated_p
           from chat_rooms
           where chat_room_id = :chat_room_id}] } { 
    ad_scope_return_error "Room deleted" "We couldn't find the chat room you tried to enter. It was probably deleted by the site administrator."
    return
}

set page_content "
[ad_scope_header "$pretty_name"]
<script runat=client>
function helpWindow(file) {
    window.open(file,'ACSchatWindow','toolbar=no,location=no,directories=no,status=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=480')
}
</script>
[ad_scope_page_title "$pretty_name"]
[chat_scope_context_bar_ws_or_index  $chat_room_id [list "index.tcl" [chat_system_name]] "Moderation" ]
<hr>"

set moderation_rows ""

switch $scope {
    public {
	set moderator [ad_administration_group_member chat $chat_room_id $user_id]
    }
    group {
	if { [ad_permission_p "" "" "" $user_id $group_id]==1 } {
	    set moderator 1
	}
    }
}

if { $moderator } {
    set moderation_rows [chat_get_posts_to_moderate $chat_room_id]
}

set formhtml "
<form action=invite method=post><div align=right>
Invite a friend - Email: <input name=email size=15><input type=submit value=invite>
[export_form_vars chat_room_id]
<input type=hidden name=return_url value=\"moderate\">
</div></form>

<form method=post action=post-message-by-moderator>
Chat: <input name=msg size=40><input type=submit value=\"Post\">
[export_form_scope_vars chat_room_id]
</form>
"

set chatters [list]
set chatters_counter 0

set private_chat_enabled_p [ad_parameter PrivateChatEnabledP chat 1]

db_foreach chat_moderate_get_users_info {select distinct user_id as chatter_id, first_names, last_name
from chat_msgs, users
where chat_msgs.creation_user = users.user_id
and chat_room_id = :chat_room_id
and creation_date > sysdate - .006944
and chat_msgs.approved_p = 't'
order by last_name} {
    incr chatters_counter

    if { $private_chat_enabled_p } {
	lappend chatters "<a href=/shared/community-member?[export_url_vars]&user_id=$chatter_id>$first_names $last_name</a> (<a target=newwindow href=message?[export_url_scope_vars]&chatter_id=$chatter_id>private chat</a>)"
    } else {
	lappend chatters "<a href=/shared/community-member?[export_url_vars]&user_id=$chatter_id>$first_names $last_name</a>"
    }
}

if $chatters_counter {
    set html_chatters "Chatters who posted messages within the last ten minutes:
    <ul>[join $chatters ", "]</ul>"
} else {
    set html_chatters ""
}

set refresh_list [list "<a href=moderate?[export_url_scope_vars chat_room_id n_rows]>Refresh</a>"]

switch -- $n_rows {
    "short" {
	set posts [chat_get_posts $chat_room_id [ad_parameter NShortMessages chat 25]]
	set more_posts_p [lindex $posts 0]
	set chat_rows [lindex $posts 1]
	if { $more_posts_p } {
	    lappend refresh_list "<a href=\"moderate?[export_url_scope_vars chat_room_id]&n_rows=medium\">More Messages</a>"
	}
    }
    
    "medium" {
	set posts [chat_get_posts $chat_room_id [ad_parameter NMediumMessages chat 50]]
	set more_posts_p [lindex $posts 0]
	set chat_rows [lindex $posts 1]
	lappend refresh_list "<a href=\"moderate?[export_url_scope_vars chat_room_id]&n_rows=short\">Fewer Messages</a>"
	if { $more_posts_p } {
	    lappend refresh_list "<a href=\"moderate?[export_url_scope_vars chat_room_id]&n_rows=long\">More Messages</a>"
	}
    }
    "long" {
	set chat_rows [lindex [chat_get_posts $chat_room_id [ad_parameter NLongMessages chat 75]] 1]
	lappend refresh_list "<a href=\"moderate?[export_url_scope_vars chat_room_id]&n_rows=medium\">Fewer Messages</a>"
    }
}



if { [ad_parameter ExposeChatHistoryP chat 1] } {
    lappend refresh_list "<a href=\"history?[export_url_scope_vars chat_room_id]\">View old messages</a>"
}

append page_content "<div align=right>\[ [join $refresh_list " | "] \]</div>"

if {[ad_parameter MostRecentOnTopP chat]} {
    append page_content $formhtml
    set formhtml ""
}

append page_content "
<ul>
$moderation_rows

$chat_rows
</ul>

$formhtml
<p>

<p>
$html_chatters
[ad_scope_footer]
"


doc_return  200 text/html $page_content

