# /www/ticket/ticket-code-set.tcl
ad_page_contract {
    Page for changing an arbitrary ticket code

    @param msg_id the ticket being changed
    @param what a code type
    @param value the new value
    @param action
    @param message
    @param msg_html one of <code>plain</code>,<code>html</code>,
           or <code>pre</code>
    @param didsubmit have they confirmed their message
    @param return_url where to go when finished
    @param project_id 
    @param domain_id

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id ticket-code-set.tcl,v 3.19.2.7 2000/09/22 01:39:24 kevin Exp
} {
    msg_id:integer,notnull
    what
    value
    action 
    message:optional,notnull,html
    {msg_html {}}
    {didsubmit {}}
    {return_url {/ticket/}}
    {project_id {}}
    {domain_id {}}
}

# -----------------------------------------------------------------------------

# fix up the message

if {[info exists message]} { 
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
    set message ""
    set raw_message {}
    if {$didsubmit == "check"} { 
        set didsubmit {}
    }
}

page_validation {
    if { [info exists html_p] && $html_p == "t" && \
	    ![empty_string_p [ad_check_for_naughty_html $message]]} {
	error [ad_check_for_naughty_html
    }

    if {![db_column_exists ticket_issues_i ${what}_id]} {
	error "Attempt to modify nonexistant database column"
    }
}

set user_id [ad_verify_and_get_user_id]
 
set mail_message {} 
set warn_msg {} 

# For the context bar if the project_id and domain_id exists
set optional_context_w_proj ""
set context_flag 0
if [exists_and_not_null project_id] {
    if [catch {set project_title_long [db_string project_title "select title_long from ticket_projects where project_id = :project_id"]} errmsg] {
	set context_flag -1
    }
    if { [exists_and_not_null domain_id] && $context_flag == 0} {
	set context_flag 1
	set modified_return_url "$return_url&project_id=$project_id&domain_id=$domain_id"
    }
}

# given a what (code_type) we look up the value and set it on the 
# ticket

# Lets get the code info

if { ![db_0or1row code_info "
select 
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
 where ti.msg_id = :msg_id 
   and tp.project_id  = ti.project_id 
   and tp.code_set = tc.code_set 
   and lower(code) = lower(:value) 
   and code_type = :what 
   and gc.comment_id(+) = ti.comment_id
   and u.user_id = :user_id" ] } {

     ad_return_complaint 1 "<LI> TR\#$msg_id does not have a code for $what:$value"
     return
}


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
set cause(close) "Closed"
set cause(fixed) "Fixed"
set cause(defer) "Deferred"
set cause(needdef) "Need info"

if {($didsubmit == "yes" && ![empty_string_p $message]) \
	|| ![info exists explain($action)]} { 
    
    db_transaction { 
        if {$action != "comment" } {
            set subject "Ticket \#$msg_id $one_line ($old_status_long -> $new_status_long)"
            set body "Status change: Ticket \#$msg_id - $one_line\nBy: $my_name $my_email\n\n"
            if { $action == "close" } { 
                set close_info ", closed_by = :user_id, closed_date = sysdate"
            } else { 
                set close_info {}
            }

            db_dml code_update "
	    update ticket_issues_i 
	    set ${what}_id = :code_id $close_info, 
	        last_modifying_user = :user_id, 
	        modified_ip_address = '[DoubleApos [ns_conn peeraddr]]', 
	        last_modified = sysdate 
	    where msg_id = :msg_id"
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
            set comment_id [db_string next_comment_id "
	    select general_comment_id_sequence.nextval from dual"]
            set cause(comment) {}
            if { ![info exists cause($action)] || [empty_string_p $cause($action)] } { 
                set item_action_desc {}
            } else { 
                set item_action_desc "\[$cause($action)\]"
            }
            
            ad_general_comment_add $comment_id {ticket_issues} $msg_id "\#$msg_id $one_line $item_action_desc" $message $user_id [ns_conn peeraddr] {t} $html_p $cause($action)
        }
    } on_error {        
        ad_return_complaint 1 "<LI>Setting $what to $value failed.  The database error was <pre>$errmsg</pre>"
        return -code return
    }

    
    # 
    # Now lets generate and send off the change notification
    #
    append page_content "
    [ad_header "Notifications sent"]
     <h2>Notifications sent</h2>"

    if {$context_flag != 1} {
	set changing_url $return_url
	append page_content "
	[ad_context_bar_ws_or_index [list $return_url {Ticket Tracker}] \
		{Notifications sent}]"
    } else {
	set changing_url $modified_return_url
	append page_content "
	[ad_context_bar_ws_or_index [list $return_url {Ticket Tracker}] \
		[list $modified_return_url $project_title_long] \
		{Notifications sent}]"
    }
    append page_content "
    <hr>
     You can now go <a href=\"$changing_url\">back to where you were</a>.<p>
     [ticket_notify change_status $msg_id $subject $body $user_id]
     [ad_footer]"

    doc_return  200 text/html $page_content
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

    append page_content "
    [ad_header "TR\#$msg_id: $one_line"]

    <h2>Confirm $action</h2>
    "

    if {$context_flag != 1} {
	append page_content "
	[ad_context_bar_ws_or_index [list $return_url {Ticket Tracker}] \
		"Confirm $action"]"
    } else {
	append page_content "
	[ad_context_bar_ws_or_index [list $return_url {Ticket Tracker}] \
		[list $modified_return_url $project_title_long] \
		"Confirm $action"]"
    }

    append page_content "
    <hr>
    $warn_msg
    Here is how your comment will appear:<blockquote><strong>$cause($action)</strong><p>"

    append page_content [util_maybe_convert_to_html $message $html_p]

    append page_content "
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
    append page_content "
    [ad_header "TR\#$msg_id: $one_line"]
    <h3>$explain($action)</h3>"

    if {$context_flag != 1} {
	append page_content "
	[ad_context_bar_ws_or_index [list $return_url {Ticket Tracker}] \
		{Comment}]"
    } else {
	append page_content "
	[ad_context_bar_ws_or_index [list $return_url {Ticket Tracker}] \
		[list $modified_return_url $project_title_long] {Comment}]"
    }

    append page_content "
 <hr>$warn_msg $badmsg
 <form method=post action=\"[ns_conn url]\">
   <textarea name=message rows=12 cols=64 wrap=soft></textarea><br>
 <b>The message above is:</b>
  <input type=radio name=msg_html value=\"pre\">Preformatted text
  <input type=radio name=msg_html value=\"plain\" checked>Plain text
  <input type=radio name=msg_html value=\"html\">HTML
  <br><blockquote><input type=submit value=\"Proceed\"></blockquote>
   [export_ns_set_vars form]
   <input type=hidden name=didsubmit value=\"check\">
</form>
<hr>
<strong>\#$msg_id - $one_line<br>Status: $old_status_long</strong><br><blockquote>$original_message</blockquote>

[ad_general_comments_list $msg_id ticket_issues "Ticket \#$msg_id: $one_line" ticket {} {} modified_long 0]

 [ad_footer]"
    
}

doc_return  200 text/html $page_content