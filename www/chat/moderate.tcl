# moderate.tcl,v 1.4.2.2 2000/02/03 09:45:38 ron Exp
# File:     /chat/moderate.tcl
# Date:     1998-11-18
# Contact:  aure@arsdigita.com,philg@mit.edu, ahmeds@arsdigita.com

# Note: if page is accessed through /groups pages then group_id and group_vars_set 
#       are already set up in the environment by the ug_serve_section. group_vars_set 
#       contains group related variables (group_id, group_name, group_short_name, 
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# this page will be the most frequently requested in the entire ACS
# it must be super efficient
# it must not query the RDBMS except in unusual cases (e.g., private chat) 

set_the_usual_form_variables

# chat_room_id, n_rows (has three possible values, "short", "medium", "long"; we do 
# this for caching)
# maybe scope, maybe scope related variables (owner_id, group_id, on_which_group, on_what_id)
# note that owner_id is the user_id of the user who owns this module (when scope=user)

ad_scope_error_check

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope registered group_member none]

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
	if { ![ad_administration_group_member $db chat $chat_room_id $user_id] } {
	    ad_scope_return_error "Not Moderator" "You are not a moderator for this chat room." $db
	    return
	}
    }
    group {
	if { ![ad_permission_p $db "" "" "" $user_id $group_id]==1 } {
	    ad_scope_return_error "Not Moderator" "You are not a moderator for this chat room." $db
	    return
	}
    }
}

# Get room info
set selection [ns_db 0or1row $db "select pretty_name, moderated_p
from chat_rooms
where chat_room_id = $chat_room_id"]

if { $selection == "" } {
    ad_scope_return_error "Room deleted" "We couldn't find the chat room you tried to enter. It was probably deleted by the site administrator." $db
    return
}

set_variables_after_query

if { ![empty_string_p $moderated_p] && $moderated_p == "t" } {
    set button_text "submit message to moderator"
} else {
    set button_text "post message"
}

set html "
[ad_scope_header "$pretty_name" $db]
<script runat=client>
function helpWindow(file) {
    window.open(file,'ACSchatWindow','toolbar=no,location=no,directories=no,status=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=480')
}
</script>
[ad_scope_page_title "$pretty_name" $db]
[chat_scope_context_bar_ws_or_index  $chat_room_id [list "exit-room.tcl?[export_url_scope_vars chat_room_id]&newlocation=index.tcl" [chat_system_name]] "Moderation" ]
<hr>"

set formhtml "<form method=post action=post-message-by-moderator.tcl>
Chat: <input name=msg size=40>
<input type=submit value=\"$button_text\">
[export_form_scope_vars chat_room_id]
<P>
</form>

"

if {[ad_parameter MostRecentOnTopP chat]} {
    append html $formhtml
    set formhtml ""
}

set moderation_rows ""


switch $scope {
    public {
	set moderator [ad_administration_group_member $db chat $chat_room_id $user_id]
    }
    group {
	if { [ad_permission_p $db "" "" "" $user_id $group_id]==1 } {
	    set moderator 1
	}
    }
}

if { $moderator } {
    set moderation_rows [chat_get_posts_to_moderate $chat_room_id]
}



set selection [ns_db select $db "select distinct user_id as chatter_id, first_names, last_name
from chat_msgs, users
where chat_msgs.creation_user = users.user_id
and chat_room_id = $chat_room_id
and creation_date > sysdate - .006944
and chat_msgs.approved_p = 't'
order by last_name"]

    set chatters [list]

    set private_chat_enabled_p [ad_parameter PrivateChatEnabledP chat 1]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	if { $private_chat_enabled_p } {
	    lappend chatters "<a href=/shared/community-member.tcl?[export_url_vars]&user_id=$chatter_id>$first_names $last_name</a> (<a target=newwindow href=message.tcl?[export_url_scope_vars]&chatter_id=$chatter_id>private chat</a>)"
	} else {
	    lappend chatters "<a href=/shared/community-member.tcl?[export_url_vars]&user_id=$chatter_id>$first_names $last_name</a>"
	}
    }

    set refresh_list [list "<a href=moderate.tcl?[export_url_scope_vars chat_room_id n_rows]>Refresh</a>"]

    switch -- $n_rows {
	"short" {
	    set posts [chat_get_posts $db $chat_room_id [ad_parameter NShortMessages chat 25]]
	    set more_posts_p [lindex $posts 0]
	    set chat_rows [lindex $posts 1]
	    if { $more_posts_p } {
		lappend refresh_list "<a href=\"moderate.tcl?[export_url_scope_vars chat_room_id]&n_rows=medium\">More Messages</a>"
	    }
	}
	
	"medium" {
	    set posts [chat_get_posts $db $chat_room_id [ad_parameter NMediumMessages chat 50]]
	    set more_posts_p [lindex $posts 0]
	    set chat_rows [lindex $posts 1]
	    lappend refresh_list "<a href=\"moderate.tcl?[export_url_scope_vars chat_room_id]&n_rows=short\">Fewer Messages</a>"
	    if { $more_posts_p } {
		lappend refresh_list "<a href=\"moderate.tcl?[export_url_scope_vars chat_room_id]&n_rows=long\">More Messages</a>"
	    }
	}
	"long" {
	    set chat_rows [lindex [chat_get_posts $db $chat_room_id [ad_parameter NLongMessages chat 75]] 1]
	    lappend refresh_list "<a href=\"moderate.tcl?[export_url_scope_vars chat_room_id]&n_rows=medium\">Fewer Messages</a>"
	}
    }

    ns_db releasehandle $db

    if { [ad_parameter ExposeChatHistoryP chat 1] } {
	set history_link "<li><a href=\"history.tcl?[export_url_scope_vars chat_room_id]\">View old messages</a>"
    } else {
	set history_link ""
    }

    ns_return 200 text/html "$html
<div align=right>
\[ [join $refresh_list " | "] \]
</div>

<ul>
$moderation_rows

$chat_rows
</ul>

$formhtml
<p>

<ul>
<form action=invite.tcl method=post>
[export_form_scope_vars chat_room_id]
<li>Invite a friend - Email: <input name=email size=15><input type=submit value=invite>
</form> 

$history_link
<li><a href=\"javascript:helpWindow('js-chat.tcl?[export_url_scope_vars chat_room_id]')\">JavaScript Version</a><br>
<li><a href=exit-room.tcl?[export_url_scope_vars chat_room_id]&newlocation=index.tcl>Exit this room</a>
</ul>

<p>

Chatters who posted messages within the last ten minutes:
<ul>
[join $chatters ", "]
</ul>

[ad_scope_footer]"
