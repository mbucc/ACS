# /tcl/chat-defs.tcl
ad_library {
    chat module private tcl

    @author Aurelius Prochazka (aure@arsdigita.com)
    @author Jin Choi (jsc@arsdigita.com)
    @author Philip Greenspun (philg@mit.edu)
    @creation-date May 1999
    @cvs-id chat-defs.tcl,v 3.5.2.6 2000/08/06 17:33:04 cnk Exp
}

proc_doc chat_system_name {} {Returns the Chat system name for presentation} {
    return [ad_parameter SystemName chat "Chat"]
}

proc_doc chat_room_group_id_internal {chat_room_id} "" {
    set bind_vars [ad_tcl_vars_to_ns_set chat_room_id]
    set group_id [db_string chat_room_group_id {
	select group_id from chat_rooms where chat_room_id = :chat_room_id
    } -bind $bind_vars -default ""]
    return $group_id 
}

proc_doc chat_room_group_id {chat_room_id} {If a private chat room, returns the ID of the group that can enter.  If the chat room is public, returns empty string.  Memoized for speed} {
    # throw an error if the argument isn't an integer (security since
    # the memoize will do an eval)
    validate_integer "chat_room_id" $chat_room_id
    return [util_memoize "chat_room_group_id_internal $chat_room_id" [ad_parameter RoomPropertiesCacheTimeout chat 600]]
}

# 5/28/2000
# mbryzek added a unique index chat_msgs_room_approved_id_idx 
# on chat_msgs(chat_room_id, approved_p, chat_msg_id)
# to avoid hitting the chat_msgs table at all when we're calling
# chat_last_post. (this is important because the JavaScript 
# client calls this like crazy)
#
#  Execution Plan
#  ----------------------------------------------------------
#     0	  SELECT STATEMENT Optimizer=CHOOSE
#     1	0   SORT (AGGREGATE)
#     2	1     INDEX (RANGE SCAN) OF 'CHAT_MSGS_ROOM_APPROVED_ID_IDX' (
#  	  UNIQUE)

proc_doc chat_last_post {chat_room_id} {Returns chat_msg_id of most recent post in a room; used by JavaScript client to figure out whether an update to the main window is needed} {
    validate_integer "chat_room_id" $chat_room_id
    set bind_vars [ad_tcl_vars_to_ns_set chat_room_id]
    set last_chat_msg_id [db_string last_chat_msg_id {
	select max(chat_msg_id) from chat_msgs where chat_room_id = :chat_room_id and approved_p = 't'
    } -bind $bind_vars -default ""]
    return $last_chat_msg_id
}

proc_doc chat_get_personal_posts {chatter_id} {Returns HTML fragment of all person-to-person messages between currently connected user and user CHATTER_ID} {

    set user_id [ad_verify_and_get_user_id]

    set order ""
    if {[ad_parameter MostRecentOnTopP chat]} {
	set order "desc"
    }

    set chat_rows ""

    db_foreach recent_personal_chat_msgs "
    select 
      to_char(creation_date,'HH24:MI:SS') as time, 
      nvl(msg_bowdlerized, msg) as filtered_msg, 
      first_names, 
      creation_user
    from 
      chat_msgs, users
    where chat_msgs.creation_user = users.user_id
      and ((creation_user = :chatter_id and recipient_user = :user_id) 
       or (creation_user = :user_id and recipient_user = :chatter_id))
    order by creation_date $order" {

	set filtered_msg [link_urls [ns_quotehtml $filtered_msg]]
	
	append chat_rows "<a target=newwindow href=/shared/community-member?user_id=$creation_user>$first_names</a> ($time) $filtered_msg\n<br>\n"
    }
    return $chat_rows
}

proc_doc chat_last_personal_post {chatter_id} {Returns a Tcl list of the time and user id of the last personal message between currently connected user and argument-specified user} {
    set user_id [ad_verify_and_get_user_id]

    set bind_vars [ad_tcl_vars_to_ns_set user_id chatter_id]

    db_foreach time_last_personal_post "
    select 
      to_char(creation_date,'HH24:MI:SS') as time, 
      creation_user
    from chat_msgs
    where (creation_user = :chatter_id
       and recipient_user = :user_id)
    or (creation_user = :user_id 
       and recipient_user = :chatter_id)
    order by creation_date desc" -bind $bind_vars {
	regsub -all ":" $time "" time
    }
    return [list $time $creation_user]
}

proc_doc chat_get_posts {chat_room_id number_of_posts} {Returns a Tcl list. The first element is 1 or 0, depending on whether or not there are more postings than requested (1 if there are more_p).  The second element is the last NUMBER_OF_POSTS messages in a chat room, as an HTML fragment, separated by BR tags} {

    set reverse_p 0
    if {[ad_parameter MostRecentOnTopP chat]} {
	set reverse_p 1
    }

    set bind_vars [ad_tcl_vars_to_ns_set chat_room_id]

    set counter 0
    set chat_rows ""

    # assume we're going to get all the chat messages
    set additional_msgs_available 0

    # we keep the query the same regardless of the order because in fact
    # we're going to be flushing the db connection; we only want the most
    # most recent N rows so we have to start at the top to hit the index and 
    # not suck 9000 old rows out of the db
    db_foreach get_recent_chat_msgs "
    select 
      to_char(creation_date, 'HH24:MI:SS') as time, 
      nvl(msg_bowdlerized, msg) as filtered_msg, 
      first_names, 
      last_name, 
      creation_user, 
      system_note_p
    from chat_msgs, users
    where chat_msgs.creation_user = users.user_id
      and chat_room_id = :chat_room_id
      and chat_msgs.approved_p = 't'
    order by creation_date desc" -bind $bind_vars {
    
	if { $counter >= $number_of_posts } {
	    # there are more msgs than we want to retrieve at the moment
	    set additional_msgs_available 1

	    # flush out the db connection and throw away the rest of the rows
	    break
	}

	incr counter

	set filtered_msg [link_urls [ns_quotehtml $filtered_msg]]

	if { $system_note_p == "t" } {
	    set row "<a target=newwindow href=\"/shared/community-member?user_id=$creation_user\">$first_names $last_name</a><font color=brown>($time) $filtered_msg</font><br>\n"
	} else {
	    set row "<a target=newwindow href=\"/shared/community-member?user_id=$creation_user\">$first_names $last_name</a> ($time) $filtered_msg<br>\n"
	}

	if { $reverse_p } {
	    append chat_rows $row
	} else {
	    set chat_rows "$row$chat_rows"
	}
    }

    # return the messages we retrieved and whether there are any more available
    return [list $additional_msgs_available $chat_rows]
}

proc_doc chat_get_posts_to_moderate {chat_room_id} {Returns HTML fragment of chat posts awaiting moderator approval.} {

    set user_id [ad_verify_and_get_user_id]

    set order ""
    if {[ad_parameter MostRecentOnTopP chat]} {
	set order "desc"
    }

    set bind_vars [ad_tcl_vars_to_ns_set chat_room_id]
    set chat_rows "<form action=moderate-2 method=post><br>Accept / Reject / Decide Later<br>"
    set ids ""

    db_foreach get_chat_msgs_needing_approval "
    select 
      to_char(creation_date,'HH24:MI:SS') as time, 
      chat_msg_id, 
      msg_bowdlerized, 
      msg, 
      content_tag, 
      first_names, 
      creation_user
    from chat_msgs, users
    where chat_msgs.creation_user = users.user_id
      and chat_room_id = :chat_room_id
      and chat_msgs.approved_p = 'f'
    order by creation_date $order" -bind $bind_vars {

	set filtered_msg [ns_quotehtml $msg]

	if { ![empty_string_p $msg_bowdlerized] } {
	    set msg_bowdlerized "([ns_quotehtml $msg_bowdlerized])"
	}

	set rating "G"
	if { $content_tag & 1 } {
	    set rating "PG"
	}
	if { $content_tag & 2 } {
	    set rating "R"
	}
	if { $content_tag & 4 } {
	    set rating "X"
	}
	
	lappend ids $chat_msg_id
	
	append chat_rows "<input type=radio name=moderate.$chat_msg_id value=t checked>
<input type=radio name=moderate.$chat_msg_id value=\"\">
<input type=radio name=moderate.$chat_msg_id value=f>
($rating) <a target=newwindow href=\"/shared/community-member?[export_url_vars user_id]\">$first_names</a> ($time) $filtered_msg $msg_bowdlerized<br>\n"
    }
    
    append chat_rows "[export_form_vars ids chat_room_id]<input type=submit value=Submit></form>"
    
    if {[empty_string_p $ids]} {
	return ""
    } else { 
	return $chat_rows
    }
}


proc_doc link_urls {str} {Replace what appear to be URLs with links.} {
    # URL courtesy of Zach Beane, somewhat modified. If you can do better,
    # let me know -jsc@arsdigita.com
    
    set url_re {(http|ftp)://[-A-Za-z0-9]+(\.[-A-Za-z0-9]+)+(:[0-9]+)?(/[-^A-Za-z0-9_~\#/]*)?([./][-^A-Za-z0-9_~\#?=%+/]+)*}
    regsub -all $url_re $str {<a target=newwindow href="\0">\0</a>} str

    # Try to get "www.photo.net" linked properly (without re-linking
    # any of the URLs we just linked).

    set url_re_no_http {([^/])(www\.[-A-Za-z0-9]+(\.[-A-Za-z0-9]+)+(:[0-9]+)?(/[-^A-Za-z0-9_~\#/]*)?([./][-^A-Za-z0-9_~\#?=%+/]+)*)}
    regsub -all $url_re_no_http $str {\1<a target=newwindow href="http://\2">\2</a>} str
    
    return $str
}

proc_doc chat_post_message {msg user_id chat_room_id} {Post message to the chat room} {

    # check that user did not send in bad html
    set naughty_html [ad_check_for_naughty_html $msg]

    if ![empty_string_p $naughty_html] {
	ad_return_warning "Invalid HTML" $naughty_html
	ad_script_abort
    }

    set bind_vars [ad_tcl_vars_to_ns_set chat_room_id]

    db_1row get_chat_room_properties_with_scope "
    select 
      group_id, 
      moderated_p, 
      scope
    from chat_rooms
    where chat_room_id = :chat_room_id" -bind $bind_vars

    set client_ip_address [ns_conn peeraddr]
    set user_id [ad_verify_and_get_user_id]

    if { $moderated_p == "t" } {
	# If one of the moderators posts a message, we immediately approve it.

	switch $scope {
	    public {
		set moderator [ad_administration_group_member chat $chat_room_id $user_id]
	    }
	    group {
		set moderator [ad_permission_p "" "" "" $user_id $group_id]
	    }
	}

	if $moderator {
	    set approved_p t
	} else {
	    set approved_p f
	}

    } else {
	set approved_p t
    }
    

    if {[empty_string_p $group_id] || [ad_user_group_member $group_id $user_id] && ![empty_string_p $msg] } {
	
        set msg_bowdlerized [bowdlerize_text $msg]
        set content_tag [tag_content $msg]
        
	catch {db_dml insert_chat_msg "
	insert into chat_msgs
	  (chat_msg_id, msg, msg_bowdlerized, content_tag, creation_date, creation_user, creation_ip_address, chat_room_id, approved_p)
	values
	  (chat_msg_id_sequence.nextval, :msg, :msg_bowdlerized, :content_tag, sysdate, :user_id,
           :client_ip_address, :chat_room_id, :approved_p)
	"} errmsg
	
	if { $approved_p == "t" } {
	    util_memoize_flush "chat_entire_page $chat_room_id short"
	    util_memoize_flush "chat_entire_page $chat_room_id medium"
	    util_memoize_flush "chat_entire_page $chat_room_id long"
	    util_memoize_flush "chat_js_entire_page $chat_room_id"
	}
    }

    return
}

proc_doc chat_post_system_note {msg user_id chat_room_id} {Post message to the chat room marked as a system note} {

    # check that user did not send in bad html
    set naughty_html [ad_check_for_naughty_html $msg]

    if ![empty_string_p $naughty_html] {
	ad_return_warning "Invalid HTML" $naughty_html
	ad_script_abort
    }

    set bind_vars [ad_tcl_vars_to_ns_set chat_room_id]

    if {![db_0or1row get_chat_room_properties "
    select group_id, moderated_p
    from chat_rooms
    where chat_room_id = :chat_room_id" -bind $bind_vars]} {
	return
    }

    set client_ip_address [ns_conn peeraddr]
    
    if {[empty_string_p $group_id] || [ad_user_group_member $group_id $user_id]} {
    
	if {![empty_string_p $msg]} {
	    set bind_vars [ad_tcl_vars_to_ns_set msg user_id client_ip_address chat_room_id]

            set bowdlerized_msg [bowdlerize_text $msg]
            if {[string compare $msg $bowdlerized_msg]} {
                set bowdlerized_msg ""
            }

            set content_tag [tag_content $msg]
	    catch {db_dml insert_chat_system_note "
	    insert into chat_msgs
	      (chat_msg_id, msg, msg_bowdlerized, content_tag, creation_date, creation_user, creation_ip_address, chat_room_id, approved_p, system_note_p)
	    values
	      (chat_msg_id_sequence.nextval, :msg, :bowdlerized_msg, :content_tag, sysdate, 
               :user_id, :client_ip_address, :chat_room_id, 't', 't')
	    " } errmsg
	}
	
	util_memoize_flush "chat_entire_page $chat_room_id short"
	util_memoize_flush "chat_entire_page $chat_room_id medium"
	util_memoize_flush "chat_entire_page $chat_room_id long"
	util_memoize_flush "chat_js_entire_page $chat_room_id"
    }
}

proc_doc chat_post_personal_message {msg user_id chatter_id} {Post a personal message from USER_ID to CHATTER_ID} {

    # check that user did not send in bad html
    set naughty_html [ad_check_for_naughty_html $msg]

    if ![empty_string_p $naughty_html] {
	ad_return_warning "Invalid HTML" $naughty_html
	ad_script_abort
    }
    
    set client_ip_address [ns_conn peeraddr]
    
    set bowdlerized_msg [bowdlerize_text $msg]
    if {[string compare $msg $bowdlerized_msg]} {
	set bowdlerized_msg ""
    }
    
    set content_tag [tag_content $msg]
    if {![empty_string_p $msg]} {

	set bind_vars [ad_tcl_vars_to_ns_set msg bowdlerized_msg user_id client_ip_address chatter_id]

	catch {db_dml insert_chat_personal_msg "
	insert into chat_msgs
	  (chat_msg_id, msg, msg_bowdlerized, content_tag, creation_date, creation_user, creation_ip_address, recipient_user)
	values
	  (chat_msg_id_sequence.nextval, :msg, :bowdlerized_msg, :content_tag, sysdate, 
           :user_id, :client_ip_address, :chatter_id)
	"} errmsg
    }
    return
}

proc chat_js_entire_page { chat_room_id } {
    set last_post_id [chat_last_post $chat_room_id]

    set whole_page "<script>
var last_post=$last_post_id;
</script>
<body bgcolor=white>
"

    if {[ad_parameter MostRecentOnTopP chat]} {
	append whole_page "<a name=most_recent></a>"
    }
    
    append whole_page "[lindex [chat_get_posts $chat_room_id 25] 1]"

    if {![ad_parameter MostRecentOnTopP chat]} {
	append whole_page "<a name=most_recent></a>"
    }

    return $whole_page
}

proc chat_entire_page { chat_room_id n_rows } {
    # n_rows has three possible values, "short", "medium", "long"

    set bind_vars [ad_tcl_vars_to_ns_set chat_room_id]

    if {![db_0or1row get_pretty_chat_room_name_and_properties "
    select pretty_name, moderated_p
    from chat_rooms
    where chat_room_id = :chat_room_id" -bind $bind_vars]} {
	ad_scope_return_error "Room deleted" "We couldn't find the chat room you tried to enter. It was probably deleted by the site administrator."
	return
    }

    if { ![empty_string_p $moderated_p] && $moderated_p == "t" } {
	set button_text "submit message to moderator"
    } else {
	set button_text "post message"
    }

    set html "
    [ad_scope_header "$pretty_name"]
    <script runat=client>
    function helpWindow(file) {
	window.open(file,'ACSchatWindow','toolbar=no,location=no,directories=no,status=no,scrollbars=yes,resizable=yes,copyhistory=no,width=450,height=480')
    }
    </script>
    "

    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    if { $scope=="public" } {
	append html "
	[ad_decorate_top "<h2>$pretty_name</h2>
	[ad_context_bar [list "exit-room.tcl?[export_url_vars chat_room_id]&newlocation=/pvt/home.tcl" "Your Workspace"] [list "exit-room.tcl?[export_url_vars chat_room_id]&newlocation=index.tcl" [chat_system_name]] "One Room"]
	" [ad_parameter DefaultDecoration chat]]
	"
    } else {
	append html "
	[ad_scope_page_title $pretty_name]
	[ad_scope_context_bar_ws_or_index  [list "exit-room.tcl?[export_url_vars chat_room_id]&newlocation=index.tcl" [chat_system_name]] "One Room"]
	"	
    }
    
    append html "
    <hr>
    "
    set formhtml "<form action=invite method=post><div align=right>
    Invite a friend - Email: <input name=email size=15><input type=submit value=invite>
    [export_form_vars chat_room_id]
    </div></form>
    <form method=post action=post-message>
    Chat: <input name=msg size=40>
    <input type=submit value=\"$button_text\">
    [export_form_vars chat_room_id n_rows]
    </form>
    "
    
    # find the people who've posted in the last 10 minutes

    set chatters [list]
    set counter 0

    db_foreach chat_user_posted_within_10_minutes "
    select 
      distinct user_id as chatter_id, 
      first_names, 
      last_name
    from chat_msgs, users
    where chat_msgs.creation_user = users.user_id
      and chat_room_id = :chat_room_id
      and creation_date > sysdate - .006944
      and chat_msgs.approved_p = 't'
    order by upper(last_name)" -bind $bind_vars {

	incr counter
	set private_chat_enabled_p [ad_parameter PrivateChatEnabledP chat 1]

	if { $private_chat_enabled_p } {
	    lappend chatters "<a href=/shared/community-member?user_id=$chatter_id>$first_names $last_name</a> (<a target=newwindow href=message?chatter_id=$chatter_id>private chat</a>)"
	} else {
	    lappend chatters "<a href=/shared/community-member?user_id=$chatter_id>$first_names $last_name</a>"
	}
    } if_no_rows {
	set html_chatters ""
    } 

    if {$counter > 0} {
	set html_chatters "Chatters who posted messages within the last ten minutes:
	<ul>[join $chatters ", "]</ul>"
    }
    
    set refresh_list [list "<a href=chat?[export_url_vars chat_room_id n_rows]>Refresh</a>"]
    
    switch -- $n_rows {
	"short" {
	    set posts [chat_get_posts $chat_room_id [ad_parameter NShortMessages chat 25]]
	    set more_posts_p [lindex $posts 0]
	    set chat_rows [lindex $posts 1]
	    if { $more_posts_p } {
		lappend refresh_list "<a href=\"chat?[export_url_vars chat_room_id]&n_rows=medium\">More Messages</a>"
	    }
	}
	
	"medium" {
	    set posts [chat_get_posts $chat_room_id [ad_parameter NMediumMessages chat 50]]
	    set more_posts_p [lindex $posts 0]
	    set chat_rows [lindex $posts 1]
	    lappend refresh_list "<a href=\"chat?[export_url_vars chat_room_id]&n_rows=short\">Fewer Messages</a>"
	    if { $more_posts_p } {
		lappend refresh_list "<a href=\"chat?[export_url_vars chat_room_id]&n_rows=long\">More Messages</a>"
	    }
	}
	"long" {
	    set chat_rows [lindex [chat_get_posts $chat_room_id [ad_parameter NLongMessages chat 75]] 1]
	    lappend refresh_list "<a href=\"chat?[export_url_vars chat_room_id]&n_rows=medium\">Fewer Messages</a>"
	}
    }

    if { [ad_parameter ExposeChatHistoryP chat 1] } {
	lappend refresh_list "<a href=\"history?[export_url_vars chat_room_id]\">View old messages</a>"
    }
    lappend refresh_list "<a href=\"javascript:helpWindow('js-chat?[export_url_vars chat_room_id]')\">JavaScript Version</a>"
    lappend refresh_list "<a href=exit-room?[export_url_vars chat_room_id]&newlocation=index>Exit this room</a>"

    append html "
    <div align=right>
    \[ [join $refresh_list " | "] \]
    </div>
    "

    if {[ad_parameter MostRecentOnTopP chat]} {
	append html $formhtml
	set formhtml ""
    }

    return "$html
    <ul>
    $chat_rows
    </ul>
    $formhtml
    <p>
    $html_chatters    
    [ad_scope_footer]
    "
    
}

proc_doc chat_history {chat_room_id} {Builds page for /chat/history.tcl; chat posts by date} {

    set bind_vars [ad_tcl_vars_to_ns_set chat_room_id]

    if {![db_0or1row pretty_chat_room_name "
    select pretty_name 
    from chat_rooms 
    where chat_room_id = :chat_room_id" -bind $bind_vars]} {
	return "
	[ad_scope_header "Room Deleted"]
	[ad_scope_page_title "Room deleted"]

	We couldn't find chat room $chat_room_id. It was probably deleted by the
	site administrator."
    }

    set whole_page "
    [ad_scope_header "$pretty_name history"]
    [ad_scope_page_title "$pretty_name history"]
    [ad_scope_context_bar_ws_or_index [list "index.tcl" [chat_system_name]] [list "chat.tcl?[export_url_vars chat_room_id]" "One Room"] "History"]

    <hr>

    <ul>
    
    "

    db_foreach chat_room_history "
    select 
      trunc(creation_date) as the_date, 
      count(*) as n_msgs
    from chat_msgs 
    where chat_room_id = :chat_room_id
      and approved_p = 't' 
      and system_note_p <> 't'
    group by trunc(creation_date)
    order by trunc(creation_date) desc" -bind $bind_vars {
	append whole_page "<li>[util_AnsiDatetoPrettyDate $the_date]:  <a href=\"history-one-day?the_date=[ns_urlencode $the_date]&chat_room_id=$chat_room_id\">$n_msgs</a>\n"
    }

    append whole_page "
    </ul>
    
    [ad_scope_footer]
    "
 
    return $whole_page
}

##################################################################
#
# interface to the ad-new-stuff.tcl system

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [lsearch -glob $ad_new_stuff_module_list "[chat_system_name]*"] == -1 } {
    lappend ad_new_stuff_module_list [list [chat_system_name] chat_new_stuff]
}

proc chat_new_stuff {since_when only_from_new_users_p purpose} {

    if { $only_from_new_users_p == "t" } {
	set query "
	select 
	  cr.chat_room_id, 
	  cr.pretty_name, count(*) as n_messages
	from chat_msgs cm, chat_rooms cr, users_new u
	where cm.chat_room_id = cr.chat_room_id
	  and cm.creation_date  > :since_when
	  and cm.creation_user = u.user_id
	 and [ad_scope_sql cr]
	group by cr.chat_room_id, cr.pretty_name"
    } else {
	set query "
	select 
	  cr.chat_room_id, 
	  cr.pretty_name, 
	  count(*) as n_messages
	from chat_msgs cm, chat_rooms cr
	where cm.chat_room_id = cr.chat_room_id
	  and cm.creation_date  > :since_when
	and [ad_scope_sql cr]
	group by cr.chat_room_id, cr.pretty_name"
    }

    set result_items ""

    db_foreach get_new_chat_history $query {
	switch $purpose {
	    web_display {
		append result_items "<li><a href=\"/chat/history?[export_url_vars chat_room_id]\">$pretty_name</a> ($n_messages new messages)\n" }
	    site_admin { 
		append result_items "<li><a href=\"/chat/history?[export_url_vars chat_room_id]\">$pretty_name</a> ($n_messages new messages)\n"
	    }
	    email_summary {
		append result_items "$pretty_name chat room : $n_messages new messages
  -- [ad_url]/chat/history.tcl?[export_url_vars chat_room_id]
"
            }
	}
    }

    # we have the result_items or not
    if { $purpose == "email_summary" } {
	return $result_items
    } elseif { ![empty_string_p $result_items] } {
	return "<ul>\n\n$result_items\n</ul>\n"
    } else {
	return ""
    }
}

# Add chat to user contributions summary.

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Chat" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Chat" ad_chat_user_contributions 1]
}

proc_doc ad_chat_user_contributions {user_id purpose} "Returns a list of priority, title, and an unordered list HTML fragment.  All the chat messages posted by a user." {
    if { $purpose == "site_admin" } {
	
	set bind_vars [ad_tcl_vars_to_ns_set user_id]

	set n_msgs [db_string count_of_user_chat_msgs "
	select count(*)
	from chat_msgs
	where creation_user = :user_id
	and system_note_p = 'f'" -bind $bind_vars]
	
        if { $n_msgs == 0 } {
	    return [list]
	}
	if { $n_msgs > 100 } {
	    return [list 1 "Chat" "More than 100 chat messages. View <a href=\"/admin/chat/msgs-for-user?user_id=$user_id\">here</a>."]
	}
	
	set items ""
	set last_chat_room ""
	set last_recipient " "
	set item_counter 0

	db_foreach user_chat_msg "
	select cr.pretty_name, cr.scope, cr.group_id, cm.msg, u.first_names || ' ' || u.last_name as recipient, ug.group_name, ug.short_name,
               decode(cr.scope, 'public', 1, 'group', 2, 'user', 3, 4) as scope_ordering
	from chat_rooms cr, chat_msgs cm, users u, user_groups ug
	where cm.creation_user = :user_id
	and cm.chat_room_id = cr.chat_room_id(+)
	and cm.recipient_user = u.user_id(+)
	and cm.system_note_p = 'f'
	and cr.group_id= ug.group_id(+)
	order by scope_ordering, cr.pretty_name, u.first_names, u.last_name, cm.creation_date desc" -bind $bind_vars {
	set last_group_id ""

	    switch $scope {
		public {
		    if { $item_counter==0 } {
			append items "
			</ul><h4>Public Chat Rooms</h4><ul>"		    
		    }
		}
		group {
		    if { $last_group_id!=$group_id } {
			append items "
			</ul><h4>$group_name Chat Rooms</h4><ul>"
		    }
		} 
	    }
	    
	    if { ![empty_string_p $pretty_name] && $last_chat_room != $pretty_name } {
		append items "Messages in $pretty_name<br><br>\n"
		set last_chat_room $pretty_name
	    }
	    if { ![empty_string_p $recipient] && $recipient != $last_recipient } {
		append items "</ul><h4>Messages to $recipient</h4><ul>\n"
		set last_recipient $recipient
	    }
	    
	    append items "<li>$msg\n"

	    set last_group_id $group_id
	    incr item_counter
	}

	return [list 1 "Chat" "<ul><ul>\n$items\n</ul></ul>"]
	
    } else {
	return [list]
    }
}

# a chat specific context bar, rooted at the workspace or index, depending on whether
# user is logged in
proc_doc chat_scope_context_bar_ws_or_index {chat_room_id args} "assumes scope is set in the callers environment. if scope=group, it assumes that group_context_bar_list are set in the callers environment. returns a Yahoo-style hierarchical contextbar for appropriate scope, starting with a link to either the workspace or /, depending on whether or not the user is logged in. Makes sure that everytime a link on the context bar is clicked, it is noted that the user has left the room" {
    if { [ad_get_user_id] == 0 } {
	set choices [list "<a href=\"exit-room?[export_url_scope_vars chat_room_id]&newlocation=/\">[ad_system_name]</a>"] 
    } else {
	set choices [list "<a href=\"exit-room?[export_url_scope_vars chat_room_id]&newlocation=[ad_pvt_home]\">Your Workspace</a>"]
    }

    set all_args [list]

    if { [uplevel [ad_scope_upvar_level] {info exists scope}] } {
	upvar [ad_scope_upvar_level] scope scope
    } else {
	set scope public
    }

    switch $scope {
	public {
	    set all_args $args
	}
	group {
	    upvar [ad_scope_upvar_level] group_vars_set group_vars_set
	    set group_context_bar_list [ns_set get $group_vars_set group_context_bar_list]
	    eval "lappend all_args $group_context_bar_list"
	    foreach arg $args {
		lappend all_args $arg
	    }
	}
	user {
	    # this may be later modified if we allow users to customize the display of their pages	    
	    set all_args $args
	}
    }

    set index 0
    foreach arg $all_args {
	incr index
	if { $index == [llength $all_args] } {
	    lappend choices $arg
	} else {
	    lappend choices "<a href=\"exit-room?[export_url_scope_vars chat_room_id]&newlocation=[lindex $arg 0]\">[lindex $arg 1]</a>"
	}
    }
    return [join $choices " : "]
}



