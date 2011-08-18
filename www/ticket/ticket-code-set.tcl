# $Id: ticket-code-set.tcl,v 3.11 2000/03/09 22:41:49 davis Exp $
#Ugh
set scope public 

ad_page_variables {
    msg_id
    what
    value
    action 
    {message {}}
    {msg_html {}}
    {didsubmit {}}
    {return_url {/ticket/}}
}


# fix up the message

if {![empty_string_p $message]} { 
    set raw_message $message
    if { $msg_html == "pre" } { 
        regsub "\[ \012\015\]+\$" $message {} message
        set message "<pre>[ns_quotehtml $message]</pre>"
        set html_p t 
    } elseif { $msg_html == "html" } { 
        set html_p t 
    } else { 
        set html_p f
    }
} else { 
    set raw_message {}
    if {$didsubmit == "check"} { 
        set didsubmit {}
    }
}

set db [ns_db gethandle]
set user_id [ad_get_user_id]
 
set mail_message {} 
set warn_msg {} 

# given a what (code_type) we look up the value and set it on the 
# ticket
util_dbq {value what}

if {![regexp {^[0-9]+$} $msg_id]} { 
    ad_return_complaint 1 "<LI> Invalid message \#$msg_id."
    return
}

# Lets get the code info

set selection [ns_db 0or1row $db "select 
  code_id,
  code as new_status,
  code_long as new_status_long,
  ti.one_line,
  ti.status_id as old_code_id,
  ti.status_long as old_status_long,
  ti.status as status_long,
  gc.content as original_message, 
  u.email as my_email,
  u.first_names || ' ' || u.last_name as my_name
 from ticket_codes tc, 
    ticket_issues ti, 
    ticket_projects tp, 
    general_comments gc, 
    users u
 where ti.msg_id = $msg_id 
   and tp.project_id  = ti.project_id 
   and tp.code_set = tc.code_set 
   and lower(code) = lower($DBQvalue) 
   and code_type = $DBQwhat 
   and gc.comment_id(+) = ti.comment_id
   and u.user_id = $user_id"]

if {[empty_string_p $selection]} { 
    ad_return_complaint 1 "<LI> TR\#$msg_id does not have a code for $what:$value"
    return
}
set_variables_after_query

if {$action != "comment" 
    && $code_id == $old_code_id} { 
    set warn_msg "<font color=red><strong>Warning: the ticket is already has status $value.</strong></font><p>"
}
    

set explain(clarify) "Please elaborate further on \#$msg_id - $one_line."
set explain(cancel) "Please explain why you are cancelling the ticket."
set explain(reopen) "Please explain why you are reopening the ticket."
set explain(comment) "Comment on \#$msg_id - $one_line"
set explain(fixed) "Please describe the work done to fix the problem."
set explain(close) "Please describe the work done to close the ticket."
set explain(defer) "Please explain why the ticket is being deferred."
set explain(needdef) "Describe what additional information is needed."

set cause(approve) "Approved"
set cause(reopen) "Reopened"
set cause(cancel) "Canceled"
set cause(clarify) "Clarification"
set cause(comment) "Comment"
set cause(close) "Fixed"
set cause(fixed) "Closed"
set cause(defer) "Deferred"
set cause(needdef) "Need info"


if {($didsubmit == "yes" && ![empty_string_p $message]) 
    || ![info exists explain($action)]} { 
    
    with_transaction $db { 
        if {$action != "comment" } {
            set subject "Ticket \#$msg_id $one_line ($old_status_long -> $new_status_long)"
            set body "Status change: Ticket \#$msg_id - $one_line\nBy: $my_name $my_email\n\n"

            ns_db dml $db "update ticket_issues_i set ${what}_id = $code_id, last_modifying_user = $user_id, modified_ip_address = '[DoubleApos [ns_conn peeraddr]]', last_modified = sysdate where msg_id = $msg_id"
        } else { 

            set subject "Ticket comment \#$msg_id $one_line"
            set body "$my_name $my_email said:\n\n"
        }

        if { $msg_html == "html" } { 
            append body [util_striphtml $message] "\n"
        } else { 
            append body $raw_message "\n"
        }
        
        if {![empty_string_p $message]} { 
            set comment_id [database_to_tcl_string $db "select general_comment_id_sequence.nextval from dual"]
            set cause(comment) {}
            if { ![info exists cause($action)] || [empty_string_p $cause($action)] } { 
                set item_action_desc {}
            } else { 
                set item_action_desc "\[$cause($action)\]"
            }
            
            ad_general_comment_add $db $comment_id {ticket_issues} $msg_id "\#$msg_id $one_line $item_action_desc" $message $user_id [ns_conn peeraddr] {t} $html_p $cause($action)
        }
    } {        
        ad_return_complaint 1 "<LI>Setting $what to $value failed.  The database error was <pre>$errmsg</pre>"
        return -code return
    }

    
    # 
    # Now lets generate and send off the change notification
    #
    ReturnHeaders
    ns_write "[ad_header "Notifications sent"]
     <h3>Notifications sent</h3>
    [ad_context_bar_ws_or_index [list $return_url {Ticket Tracker}] {Notifcations sent}]
    <hr>
     You can now go <a href=\"$return_url\">back to where you were</a>.<p>
     [ticket_notify $db change_status $msg_id $subject $body $user_id]
     [ad_footer]"

    
    return
}


#
# We need a message for this state transition
#

if { $didsubmit == "yes"} { 
    set badmsg "<strong><font color=red>You must provide a message to explain this action.</font></strong><p>"
} else {
    set badmsg {}
}



if {[string compare $didsubmit "check"] == 0} { 

    # Confirmation of comment 

    ReturnHeaders 

    ns_write "[ad_header "TR\#$msg_id: $one_line"]<h3>Confirm $action</h3>
 [ad_context_bar_ws_or_index [list $return_url {Ticket Tracker}] "Confirm $action"]<hr>
 $warn_msg
 Here is how your comment will appear:<blockquote><strong>$cause($action)</strong><p>"
    if {$html_p == "t" } {
        ns_write $message
    } else { 
        ns_write [util_convert_plaintext_to_html $message]
    }
    ns_write "
   <form method=post action=\"[ns_conn url]\">
   [export_ns_set_vars form didsubmit]
   <input type=hidden name=didsubmit value=\"yes\">
  <br><blockquote><input type=submit value=\"Confirm\">
 </blockquote>
 </blockquote>


 </form>
 <font size=-1 face=\"verdana, arial, helvetica\">
 Note: if the text above has a bunch of visible HTML tags then you probably
 should have selected \"HTML\" rather than \"Plain Text\".  Use your
 browser's Back button to return to the submission form.  If it is all smashed
 together and you want the original line breaks saved then choose \"Preformatted Text\".
 </font>

 [ad_footer]"
} else { 
    # Initial entry of comment 
    ReturnHeaders 
    ns_write "[ad_header "TR\#$msg_id: $one_line"]<h3>$explain($action)</h3>
 [ad_context_bar_ws_or_index [list $return_url {Ticket Tracker}] {Comment}]
 <hr>$warn_msg $badmsg
 <form method=post action=\"[ns_conn url]\">
   <textarea name=message rows=12 cols=64 wrap=soft></textarea><br>
 <b>The message above is:</b>
  <input type=radio name=msg_html value=\"pre\">Prefomatted text
  <input type=radio name=msg_html value=\"plain\" checked>Plain text
  <input type=radio name=msg_html value=\"html\">HTML
  <br><blockquote><input type=submit value=\"Proceed\"></blockquote>
   [export_ns_set_vars form]
   <input type=hidden name=didsubmit value=\"check\">
</form>"
    ns_write "<hr><strong>\#$msg_id - $one_line<br>Status: $old_status_long</strong><br><blockquote>$original_message</blockquote>"
    ns_write "[ad_general_comments_list $db $msg_id ticket_issues "Ticket \#$msg_id: $one_line" ticket {} {} modified_long 0]
 [ad_footer]"
    
}