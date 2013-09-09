# /webmail/message.tcl

ad_page_contract {
    Displays a single message.

    @param msg_id ID of message to display
    @param header_display_style can be "short" or "all"
    @param body_display_style can be "parsed" or "unparsed"
    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id message.tcl,v 1.6.2.5 2000/09/22 01:39:28 kevin Exp
} {
    msg_id:integer
    { header_display_style "short" }
    { body_display_style "parsed" }
}

set user_id [ad_verify_and_get_user_id]

# See if user has permission to read this message, and at the same time get
# the mailbox_id of this message.
set message_exists_p [db_0or1row mailbox_info "select m.mailbox_id, m.name as mailbox_name, mmm.deleted_p
from wm_message_mailbox_map mmm, wm_mailboxes m
where mmm.msg_id = :msg_id
  and mmm.mailbox_id = m.mailbox_id
  and m.creation_user = :user_id"]

if { !$message_exists_p } {
    ad_return_error "No Such Message" "The specified message could not be found.
Either you do not have permission to read this message, or it has been deleted."
    return
}

set mime_message_p 0

set msg_body [db_string mime_text "select mime_text
from wm_messages
where msg_id = :msg_id"]

if { $msg_body != "" } {
    set mime_message_p 1
}

if { $body_display_style == "parsed" } {
    if { $msg_body != "" } {
	set quoted_msg_body [philg_quote_double_quotes $msg_body]
	regsub -all "##wm_image: (\[^\n\]+)" $quoted_msg_body "<img src=\"parts/$msg_id/\\1\">" final_msg_body
	regsub -all "##wm_part: (\[^\n\]+)" $final_msg_body "<b>Attachment:</b> <a href=\"parts/$msg_id/\\1\">\\1</a>" final_msg_body
    }
}

if { $body_display_style == "unparsed" || $msg_body == "" } {
    set msg_body [db_string body "select body
from wm_messages
where msg_id = :msg_id"]
    if { [db_string headercount "select count(*) 
from wm_headers
where msg_id = :msg_id
  and lower_name = 'content-type'
  and value like 'text/html%'"] > 0 } {
	set final_msg_body $msg_body
    } else {
	set final_msg_body [philg_quote_double_quotes $msg_body]
    }
}

if { $header_display_style == "short" } {
    set change_header_display_link "<font size=-1><a href=\"message?msg_id=$msg_id&header_display_style=all\">Show all headers</a></font>"
} else {
    set change_header_display_link "<font size=-1><a href=\"message?msg_id=$msg_id&header_display_style=short\">Hide headers</a></font>"
}

if $mime_message_p {
    if { $body_display_style == "parsed" } {
	set change_body_display_link "<font size=-1><a href=\"message?[export_url_vars msg_id header_display_style]&body_display_style=unparsed\">Show unparsed message</a></font>"
    } else {
	set change_body_display_link "<font size=-1><a href=\"message?[export_url_vars msg_id header_display_style]&body_display_style=parsed\">Show decoded message</a></font>"
    }
} else {
    set change_body_display_link ""
}




set msg_headers [wm_header_display $msg_id $header_display_style $user_id]


set current_messages [ad_get_client_property "webmail" "current_messages"]

set folder_select_options [db_html_select_value_options mailbox_selection "select mailbox_id, name
from wm_mailboxes
where creation_user = :user_id
and mailbox_id <> :mailbox_id"]

if { [empty_string_p $folder_select_options] } {
    set folder_refile_widget ""
} else {
    set folder_refile_widget "<form action=\"message-refile\" method=POST>
[export_form_vars msg_id]
<input type=submit value=\"Refile\">
<select name=mailbox_id>
<option value=\"\">Select Folder</option>
$folder_select_options
</select>
</form>
"
}


db_dml seen_p_update "update wm_message_mailbox_map
set seen_p = 't'
where msg_id = :msg_id"

db_release_unused_handles

# Returns HTML to provide navigation links for previous unread, previous,
# next, and next unread messages. If the next message is unread, only provides
# next unread link. Same for previous and previous unread.

proc wm_message_navigation_links { current_msg_id current_messages } {
    set prev_unread ""
    set prev ""
    set next_unread ""
    set next ""
    set looking_for_next_message_p 0
    set looking_for_next_unread_message_p 0

    set last_unread ""
    set last ""
    
    foreach message $current_messages {
	set msg_id [lindex $message 0]
	set seen_p [lindex $message 1]
	set deleted_p [lindex $message 2]

	if { $msg_id == $current_msg_id } {
	    set prev_unread $last_unread
	    set prev $last
	    set looking_for_next_message_p 1
	    continue
	}

	if { $deleted_p == "t" } {
	    continue
	}

	if { $looking_for_next_unread_message_p } {
	    if { $seen_p == "t" } {
		continue
	    } else {
		set next_unread $msg_id
		break
	    }
	}

	if { $looking_for_next_message_p } {
	    set next $msg_id

	    if { $seen_p == "t" } {
		set looking_for_next_unread_message_p 1
		continue
	    } else {
		set next_unread $msg_id
		break
	    }
	}
	
	
	if { $seen_p == "f" } {
	    set last_unread $msg_id
	}
	set last $msg_id
    }

    set nav_links [list]

    if { $prev_unread != "" } {
	lappend nav_links "<a href=\"message?msg_id=$prev_unread\">Previous Unread</a>"
    } else {
	lappend nav_links "<font color=\"lightgray\">Previous Unread</font>"
    }

    if { $prev != "" } {
	lappend nav_links "<a href=\"message?msg_id=$prev\">Previous</a>"
    } else {
	lappend nav_links "<font color=\"lightgray\">Previous</font>"
    }

    if { $next != "" } {
	lappend nav_links "<a href=\"message?msg_id=$next\">Next</a>"
    } else {
	lappend nav_links "<font color=\"lightgray\">Next</font>"
    }

    if { $next_unread != "" } {
	lappend nav_links "<a href=\"message?msg_id=$next_unread\">Next Unread</a>"
    } else {
	lappend nav_links "<font color=\"lightgray\">Next Unread</font>"
    }
    return [join $nav_links " - "]
}



doc_return  200 text/html "[ad_header "One Message"]
<h2>$mailbox_name</h2>

[ad_context_bar_ws [list "index?[export_url_vars mailbox_id]" "WebMail ($mailbox_name)"] "One Message"]

<hr>

[wm_message_navigation_links $msg_id $current_messages]
<p>
<a href=\"message-send?response_to_msg_id=$msg_id\">Reply</a> -
<a href=\"message-send?response_to_msg_id=$msg_id&respond_to_all=1\">Reply All</a>


$folder_refile_widget

[ad_decode $deleted_p "f" "<form action=\"message-delete\" method=POST>
[export_form_vars msg_id]
<input type=submit value=\"Delete\">
</form>" "<form action=\"process-selected-messages\" method=POST>
[export_form_vars mailbox_id]
<input type=hidden name=msg_ids [export_form_value msg_id]>
<input type=hidden name=return_url value=\"message?[export_ns_set_vars url]\">
<input type=submit name=action value=\"Undelete\">
</form>"]

<blockquote>
$msg_headers
$change_header_display_link
<p>
$change_body_display_link
<pre>
$final_msg_body
</pre>
</blockquote>

$folder_refile_widget

[ad_decode $deleted_p "f" "<form action=\"message-delete\" method=POST>
[export_form_vars msg_id]
<input type=submit value=\"Delete\">
</form>" ""]



[ad_footer]
"