# $Id: ticket-defs.tcl,v 3.9.2.2 2000/04/28 15:08:19 carsten Exp $
# Ticket tracker support routines.

util_report_library_entry


# 
# Routines for configuration support 
# 
proc_doc ticket_system_name {} {
    returns the ticket system name.
} { 
    return "Ticket Tracker"
}

proc ticket_getdbhandle {} {
    return [ns_db gethandle main]
}

proc_doc ticket_mail_footer {} {
    Returns the footer associated with the ticket
} { 
    return [ad_parameter TicketMailFooter ticket "-- automatically sent from [ticket_system_name] --"]
}

proc_doc ticket_mail_send {addresses} {
    This will override the adressees if the parameter
    TicketMailTester is non-empty.
} { 
    set ticket_mail_tester [ad_parameter TicketMailTester ticket ""]
    if {![empty_string_p $ticket_mail_tester]} { 
        return $ticket_mail_tester
    } else { 
        return $addresses
    }
}

proc_doc ticket_mail_send_body {addresses body} {
    This will rewrite the message body if the variable
    TicketMailTester is non-empty.
} { 
    set ticket_mail_tester [ad_parameter TicketMailTester ticket {}]
    if {![empty_string_p $ticket_mail_tester]} { 
        return "Debug...Sent to: [ticket_mail_send $addresses]\na message really for:$addresses\n\nBody:\n$body"
    } else { 
        return $body
    }
}

proc_doc ticket_assignee_select {db project_id domain_id group_id user_id {default_message {-- None assigned --}} {variable {}}} {
    given a group_id and user_id generate a select 
    widget for choosing a new default user 
    to feed to ticket-assignments-update.tcl
} { 
    if {[empty_string_p $variable]} { 
        set variable a_${project_id}_${domain_id}_$user_id
    }
    return [ad_db_select_widget -default $user_id  -hidden_if_one_db 1 -blank_if_no_db 1 \
                -option_list [list [list {} $default_message]] $db \
	    "select u.last_name || ', ' || u.first_names || ' (' || u.email || ')' as uname, u.user_id
from users u
where ad_group_member_p(u.user_id, $group_id) = 't'
order by upper(u.last_name) asc, upper(u.first_names) asc" $variable]
}


proc_doc ticket_actions {msg_id status_class status_subclass responsibility user_id ticket_user_id assigned_user_id return_url where {type line}} { 
    generate the ticket actions as seen in the index.tcl table 
    and at the bottom of issue-view.
} {
    set out {}
    set join {}
    set comment(list) {Add a comment}
    set view(list) {View the ticket}
    set edit(list) {Edit the ticket}
    set clarify(list) {Clarify the ticket}
    set makecopy(list) {Make a duplicate of the ticket}
    set move(list) {Move the ticket to another project}
    set close(list) {Close the ticket}
    set cancel(list) {Cancel the ticket}
    set reopen(list) {Reopen the ticket}
    set approve(list) {Approve the fix}
    set changes(list) {View the ticket change history}
    set fixed(list) {Mark the ticket as fixed}
    set needdef(list) {Need more information to resolve}
    set defer(list) {Defer the ticket}



    set comment(line) {comment} 
    set view(line) {view}
    set edit(line) {edit}
    set makecopy(line) {copy}
    set move(line) {move}
    set clarify(line) {clarify}
    set close(line) {close}
    set cancel(line) {cancel}
    set reopen(line) {reopen}
    set approve(line) {approve}
    set changes(line) {view changes}
    set fixed(line) {fixed}
    set needdef(line) {need info}
    set defer(line) {defer}

    if {$where != "index" } {
        lappend out "<a href=\"ticket-code-set.tcl?msg_id=$msg_id&what=status&value=closed&action=comment&return_url=[ns_urlencode "[ns_conn url]?[export_ns_set_vars url]"]\">$comment($type)</a>"
    } 
    if {$where != "view" } {
        lappend out "<a href=\"/ticket/issue-view.tcl?msg_id=$msg_id&$return_url\">$view($type)</a>"
    }

    if {$where != "edit" } { 
        lappend out "<a href=\"/ticket/issue-new.tcl?msg_id=$msg_id&mode=full&$return_url\">$edit($type)</a>"
    } 
    if {$type == "list"} { 
        lappend out "<a href=\"ticket-move.tcl?msg_id=$msg_id&$return_url\">$move($type)</a>"
        #lappend out "<a href=\"issue-new.tcl?ascopy=1&msg_id=$msg_id&project_id=&$return_url\">$makecopy($type)</a>"
        lappend out "<a href=\"issue-audit.tcl?msg_id=$msg_id&$return_url\">$changes($type)</a>"
        lappend out "<a href=\"ticket-watch.tcl?msg_id=$msg_id&return_url=[ns_urlencode "[ns_conn url]?[export_ns_set_vars url]"]\">Watch this ticket (get email on all activity)</a>"
    } 

    # this is a huge mess.  fix later.  should just be data driven.
    if { $user_id == $ticket_user_id 
         && $user_id != $assigned_user_id } {
        if {$status_subclass == "approve"
            && $responsibility == "user" } {
            lappend out "<a href=\"ticket-code-set.tcl?msg_id=$msg_id&what=status&value=closed&action=approve&$return_url\">$approve($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$approve($type)</em>"
        }
        
        if {$status_subclass == "clarify"
            && $responsibility == "user" } { 
            lappend out "<a href=\"ticket-code-set.tcl?msg_id=$msg_id&what=status&value=open&action=clarify&$return_url\">$clarify($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$clarify($type)</em>"
        }
        if {$status_class == "active" 
            && $status_subclass != "approve"} { 
            lappend out "<a href=\"ticket-code-set.tcl?msg_id=$msg_id&what=status&value=closed&action=cancel&$return_url\">$cancel($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$cancel($type)</em>"
        }        
    }

    if {$user_id == $ticket_user_id || $user_id == $assigned_user_id} { 
        if { ($status_class == "closed" && $user_id == $ticket_user_id)
             || ($status_class == "deferred" && $user_id == $assigned_user_id) } {
            lappend out "<a href=\"ticket-code-set.tcl?msg_id=$msg_id&what=status&value=open&action=reopen&$return_url\">$reopen($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$reopen($type)</em>"
        }
    }

    # assigned user actions
    if { $user_id == $assigned_user_id } {
        if {$status_class == "active" 
            && $status_subclass != "approve" } { 
            lappend out "<a href=\"ticket-code-set.tcl?msg_id=$msg_id&what=status&value=need%20def&action=needdef&$return_url\">$needdef($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$needdef($type)</em>"
        }

        if {$status_class == "active" 
            && $status_subclass != "approve" } { 
            lappend out "<a href=\"ticket-code-set.tcl?msg_id=$msg_id&what=status&value=defer&action=defer&$return_url\">$defer($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$defer($type)</em>"
        }

        if {$status_class == "active" 
            && $status_subclass != "approve" } { 
            lappend out "<a href=\"ticket-code-set.tcl?msg_id=$msg_id&what=status&value=Fix/AA&action=fixed&$return_url\">$fixed($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$fixed($type)</em>"
        }
    } 
    
    if {$user_id == $ticket_user_id || $user_id == $assigned_user_id} { 
        if {$status_class == "active" } { 
            lappend out "<a href=\"ticket-code-set.tcl?msg_id=$msg_id&what=status&value=closed&action=close&$return_url\">$close($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$close($type)</em>"
        }
    }

    switch $type { 
        line { 
            return [join $out " | "]
        }
        
    }
    return "<UL><LI>[join $out {<LI>}]</UL>"
}


proc_doc ticket_report {db selection view table_def} { 
    generate a report from an active DB query.
} { 
    set i 0
    set html {} 
    while {[ns_db getrow $db $selection]} { 
        set_variables_after_query
        if {![info exists seen($msg_id)]} { 
            set seen($msg_id) 1
            set order($i) $msg_id
            set line($msg_id) "<p><strong><a href=\"issue-view.tcl?msg_id=$msg_id\">\#$msg_id $one_line</a></strong><br>Project: <strong>$project_title_long</strong> Feature Area: <strong>$domain_title_long</strong> Status: <strong>$status_long</strong> Creation Date: <strong>$creation_mdy</strong> Severity: <strong>$severity_long</strong><br>"
            if { $view == "full_report" } {
                append chtml($msg_id) "<blockquote>$message<br>-- $user_name &lt;<a href=\"mailto:$email\">$email</a>&gt;</blockquote>"
            }
            incr i
        } 
        if {![empty_string_p $assigned_user_email ]} { 
            lappend ass($msg_id) "<a href=\"mailto:$assigned_user_email\">$assigned_user_email</a>"
        }
    }
    
    if { $i < 1 } { 
        return "<br><em>No data found.</em><br>"
    }

    # ok now for full reports we need to go get the 
    # messages...we can use db since we just finished the query...
    if {$view == "full_report"} {
        set selection [ns_db select $db "select gc.on_what_id, gc.comment_id, gc.client_file_name,
    gc.file_type, gc.original_width, gc.original_height, gc.caption, gc.content, gc.html_p, 
    u.last_name, u.first_names, u.email, u.user_id, 
    to_char(comment_date, 'Month, DD YYYY HH:MI AM') as comment_date_long
  from general_comments gc, users u
  where on_which_table = 'ticket_issues' 
    and u.user_id = gc.user_id 
    and on_what_id in ([join [array names seen] {,}]) 
  order by comment_date asc"]
    
        while {[ns_db getrow $db $selection]} { 
            set_variables_after_query
            append chtml($on_what_id) "[format_general_comment $comment_id $client_file_name $file_type $original_width $original_height $caption $content $html_p]<br> -- $first_names $last_name &lt;<a href=\"mailto:$email\">$email</a>&gt; on $comment_date_long<br>"
        }
    }

    for {set m 0} { $m < $i } { incr m } {
        append html "$line($order($m))" 
        set line($order($m)) {}
        if {[info exists ass($order($m))]} { 
            append html "Assigned to: [join $ass($order($m)) {, }]<br>"
        }
        if {[info exists chtml($order($m))]} { 
            append html "<blockquote>$chtml($order($m))</blockquote>"
            set chtml($order($m)) {}
        }
    }
    return $html
}


proc_doc ticket_feedback_link {{text {Feedback}}} {
    returns the html for a link into the ticket system for 
    page feedback
    <p>
    Note that this function assumes that project_id 1 is the "Feedback" project
} {
    return "<a href=\"/ticket/issue-new.tcl?project_id=1&from_host=[ns_urlencode [ns_conn location]]&from_url=[ns_urlencode [ns_conn url]]&fq_len=[string length [ns_conn query]]&from_query=[ns_urlencode [ns_conn query]]\">$text</a>"
}

proc_doc ticket_page_link {{text {Page ticket}}} {
    returns the html for a link into the ticket system for 
    page tickets
    <p>
    Note that this function assumes that project_id 0 is the "Incoming" project
} {
    return "<a href=\"/ticket/issue-new.tcl?project_id=0&from_host=[ns_urlencode [ns_conn location]]&from_url=[ns_urlencode [ns_conn url]]&fq_len=[string length [ns_conn query]]&from_query=[ns_urlencode [ns_conn query]]\">$text</a>"
}

proc blank_zero {n} {
    if {"$n" == "0"} {
	return ""
    } else {
	return $n
    }   
}



##################################################################
#
# interface to the ad-user-contributions-summary.tcl system

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] 
     || [util_search_list_of_lists $ad_user_contributions_summary_proc_list \
             [ticket_system_name] 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list \
        [list [ticket_system_name] ticket_user_contributions 0]
}

proc_doc ticket_user_contributions {db user_id purpose} {Returns list items, one for each bboard posting} {
    if { $purpose != "site_admin" } {
	return [list]
    } 
    set selection [ns_db 0or1row $db "select 
    count(tia.msg_id) as total,
    sum(decode(status_class,'closed',1,0)) as closed,
    sum(decode(status_class,'closed',0,'deferred',0,NULL,0,1)) as open,
    sum(decode(status_class,'deferred',1,0)) as deferred,
    max(last_modified) as lastmod,
    min(posting_time) as oldest,
    sum(ticket_one_if_high_priority(priority, status)) as high_pri,
    sum(ticket_one_if_blocker(severity, status)) as blocker
  from ticket_issues ti, ticket_issue_assignments tia
  where tia.user_id = $user_id
    and ti.msg_id = tia.msg_id"]

    if { [empty_string_p $selection] } {
	return [list]
    }

    set_variables_after_query
    if { $total == 0 } {
	return [list]
    }

    set items "<li>Total tickets:  $total ($closed closed; $open open; $deferred deferred)
 <li>Last modification:  [util_AnsiDatetoPrettyDate $lastmod]
 <li>Oldest:  [util_AnsiDatetoPrettyDate $oldest]
 <p>
 Details:  <a href=\"/ticket/admin/user-top.tcl?search_user_id=$user_id\">view the tickets</a>\n"
    return [list 0 [ticket_system_name] "<ul>\n\n$items\n\n</ul>"]
}


################################################################## 
#
# interface to the ad-new-stuff.tcl system

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] 
      || [util_search_list_of_lists $ad_new_stuff_module_list [ticket_system_name] 0] == -1 } {
    lappend ad_new_stuff_module_list [list [ticket_system_name] ticket_new_stuff]
}


proc_doc ticket_new_stuff {db since_when only_from_new_users_p purpose} {
    Only produces a report for the site administrator; the assumption is that 
    random users won't want to see trouble tickets
} { 
    if { $purpose != "site_admin" } {
 	return {}
    }
    
    if { $only_from_new_users_p == "t" } {
 	set users_table "users_new"
    } else {
	set users_table "users"
    }
    set query "select ti.msg_id, ti.one_line, ut.email, ut.first_names || ' ' || ut.last_name as user_name, ut.user_id
 from ticket_issues ti, $users_table ut
 where posting_time > '$since_when'
 and ti.user_id = ut.user_id"
    set result_items {}
    set selection [ns_db select $db $query]
    while { [ns_db getrow $db $selection] } {
 	set_variables_after_query
 	append result_items "<li><a href=\"/ticket/issue-new.tcl?[export_url_vars msg_id]\">$one_line</a> by <a href=\"/admin/users/one.tcl?user_id=$user_id\">$user_name</a> (<a href=\"mailto:$email\">$email</a>)"
    }
    if { ![empty_string_p $result_items] } {
	return "<ul>\n\n$result_items\n</ul>\n"
    } else {
 	return ""
    }
}

# returns 1 if current user is in admin group for ticket module
proc ticket_user_admin_p {db} {
    set user_id [ad_verify_and_get_user_id]
    return [ad_administration_group_member $db ticket "" $user_id]
}

# return the GID of the ticket admin group
proc ticket_admin_group {db} {
    return [ad_administration_group_id $db "ticket" ""]
}

ns_share -init {set ad_ticket_filters_installed 0} ad_ticket_filters_installed

if {!$ad_ticket_filters_installed} {
    ad_register_filter preauth HEAD /ticket/admin/* ticket_security_checks_admin
    ad_register_filter preauth HEAD /ticket/*       ticket_security_checks
    ad_register_filter preauth GET  /ticket/admin/* ticket_security_checks_admin
    ad_register_filter preauth GET  /ticket/*       ticket_security_checks
    ad_register_filter preauth POST /ticket/admin/* ticket_security_checks_admin
    ad_register_filter preauth POST /ticket/*       ticket_security_checks
}

# Check for the user cookie, redirect if not found.
proc ticket_security_checks {args why} {
    uplevel {
	set user_id [ad_verify_and_get_user_id]
	if {$user_id == 0} {
	    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	    return filter_return
	} 
	return filter_ok
    }
}


# Checks if user is logged in, AND is a member of the ticket admin group
proc ticket_security_checks_admin {args why} {
    set user_id [ad_verify_and_get_user_id]
    if {$user_id == 0} {
	ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    } 

    set db [ns_db gethandle subquery]
    
    if {![ticket_user_admin_p $db]} {
        # need to release subquery!
        ns_db releasehandle $db
	ad_return_error "Access Denied" "Your account does not have access to this page."
	return filter_return
    }
	
    ns_db releasehandle $db

    return filter_ok
}


proc ticket_reply_email_addr {{msg_id ""} {user_id 0}} {
    if {[empty_string_p $msg_id]} { 
        return [ad_parameter TicketReplyEmail ticket]
    } else { 
        return "ticket-$msg_id-$user_id@[ad_parameter TicketReplyHost ticket "nowhere.tv"]"        
    }
}

proc_doc ticket_notify {db what msg_id subject body {excluded_users {}}} { 
    send mail to people who should know about this 
    change.

    what -- new_ticket updated_ticket copied_ticket status_change etc (so we don;t notify submitter on new ticket for example)
} { 
    set precedence {watcher admin assignee submitter} 
    # Currently watches unimplemented

    foreach who $precedence { 
        switch $who { 
            watcher { 
                # set all admins 
                set query 1
                set selection [ns_db select $db "select
 u.email as notify_email, u.first_names || ' ' || u.last_name as user_name,
   u.user_id as notify_user_id
 from users_spammable u, ticket_email_alerts tea, ticket_issues ti
 where  u.user_id = tea.user_id 
   and ti.msg_id = $msg_id 
   and (tea.msg_id = ti.msg_id
        or (tea.domain_id = ti.domain_id and tea.project_id is null)
        or (tea.domain_id is null and tea.project_id = ti.project_id)
        or (tea.domain_id = ti.domain_id and tea.project_id = ti.project_id))"]
                set is_a "watcher"
            }
            
            admin { 
                # set all admins -- do not spam if notify_admin_p is false.
                set query 1
                set selection [ns_db select $db "select
  u.email as notify_email,
  u.first_names || ' ' || u.last_name as user_name,
   u.user_id as notify_user_id
 from users_spammable u,
  ticket_issues t, 
  ticket_domains td, 
  ticket_projects tp, 
  user_group_map ugm
 where  u.user_id = ugm.user_id 
  and t.msg_id = $msg_id 
  and td.domain_id = t.domain_id 
  and ugm.group_id = td.group_id 
  and ugm.role = 'administrator'
  and td.notify_admin_p = 't'"]
                set is_a "admin"
            }

            assignee { 
                # set all assigned users 
                set query 1
                set selection [ns_db select $db "select
 u.email as notify_email, u.first_names || ' ' || u.last_name as user_name, 
   u.user_id as notify_user_id
 from users_spammable u, ticket_issue_assignments tia, ticket_issues t
 where tia.msg_id = $msg_id
 and u.user_id = tia.user_id and t.msg_id = $msg_id and tia.msg_id = t.msg_id"]
                set is_a "assignee"
            }
            
            submitter { 
                if {[lsearch -exact {new_ticket} $what] < 0} { 
                    set query 1
                    set selection [ns_db select $db "select
 u.email as notify_email, u.first_names || ' ' || u.last_name as user_name,
   u.user_id as notify_user_id
 from users_spammable u, ticket_issues t where t.user_id = u.user_id and t.msg_id = $msg_id"]
                    set is_a submitter
                } else { 
                    set query 0
                }
            }
            
            default { 
                set query 0
            }
        }

        if { $query } { 
            while { [ns_db getrow $db $selection] } { 
                set_variables_after_query
                if {[lsearch -exact $excluded_users $notify_user_id] < 0} { 
                    # not on the exclude list...
                    set mail_name($notify_email) "$user_name"
                    set mail_user_id($notify_email) "$notify_user_id"
                    set mail_is_a($notify_email) "$is_a"
                }
            }
        }
    }
    set pretty_is_a(watcher) "Has watches set:"
    set pretty_is_a(admin) "Administrator:"
    set pretty_is_a(submitter) "Original submitter:"
    set pretty_is_a(assignee) "Assigned to Ticket:"

    set send_to {}
    set send_to_html {The following people have been notified:<ul>}
    foreach user_is_a $precedence {
        set i 0
        foreach who [array names mail_is_a] { 
            if { $mail_is_a($who) == "$user_is_a"} { 
                if {$i == 0}  { 
                    append send_to " $pretty_is_a($user_is_a)\n"
                }
                append send_to "   $mail_name($who) - $who\n"
                append send_to_html "<li> <a href=\"mailto:$who\">$mail_name($who)</a> <em>($user_is_a)</em><br>\n"
                incr i
            }
        }
    }

    append send_to_html {</ul><p>}

    set extra_headers [ns_set create] 
    
    foreach who [array names mail_is_a] { 
        ns_set update $extra_headers "Reply-To" [ticket_reply_email_addr $msg_id $mail_user_id($who)] 

	if {[catch {ns_sendmail [ticket_mail_send $who] \
                        [ticket_reply_email_addr] \
                        $subject \
                        [ticket_mail_send_body $who "$body\n\n$send_to\nManage via [ns_conn location]/ticket/issue-view.tcl?msg_id=$msg_id"] \
                        $extra_headers} errmsg]} { 
            append send_to_html "Error for $who<pre>$errmsg</pre>"
        }
    }

    append send_to_html "Subject: <strong>[ns_quotehtml $subject]</strong><pre>[ns_quotehtml $body]</pre>\nManage via <a href=\"[ns_conn location]/ticket/issue-view.tcl?msg_id=$msg_id\">[ns_conn location]/ticket/issue-view.tcl?msg_id=$msg_id</a>"
    return $send_to_html
}

proc_doc ticket_context context {
    given a list this generates the ticket context bar
} { 
    set context_last [expr [llength $context] - 1]
    set context [lreplace $context $context_last end [lindex [lindex $context $context_last] 1]]
    return [eval ad_context_bar_ws_or_index $context]
}

proc_doc ticket_assigned_users {db project_id domain_id domain_group_id msg_id one_line my_return_url {admin_p 0} } { 
    generate the list of assigned users with remove and picklist 
    to add more if an admin for the group to which the ticket is assigned
} { 
    set selection [ns_db select $db "select
  last_name || ', ' || first_names as assigned_name,
  u.email as assigned_email,
  u.user_id as assigned_user_id
  from users u, ticket_issue_assignments tia where tia.msg_id = $msg_id and u.user_id = tia.user_id
  order by upper(last_name) asc, upper(first_names) asc"]

    set users {}
    set pre {<strong>Assigned users:</strong><ul><li>}
    while {[ns_db getrow $db $selection]} { 
        set_variables_after_query
        append users "$pre [ticket_user_display $assigned_name $assigned_email $assigned_user_id ] &lt<a href=\"mailto:$assigned_email\">$assigned_email</a>&gt;"
        if { $admin_p } { 
            append users " (<a href=\"/ticket/ticket-remove-assignment.tcl?msg_id=$msg_id&user_id=$assigned_user_id&$my_return_url\">remove</a>)"
        }
        set pre {<li>}
    }

    if {[empty_string_p $users]} { 
        append users "<br><strong><font color=red>No assigned users</font></strong><br>"
    } else { 
        append users "</ul>"
        
    }

    # add assignment
    if { $admin_p } { 
        append users "<form method=get action=\"/ticket/ticket-update-assignment.tcl\">
      Assign to: [ticket_assignee_select $db $project_id $domain_id $domain_group_id {} {-- Remove all assignees --}]
      <input type=hidden name=return_url value=\"[philg_quote_double_quotes "[ns_conn url]?[export_ns_set_vars url]"]\">
      <input type=hidden name=one_line value=\"[philg_quote_double_quotes $one_line]\">
      <input type=hidden name=msg_id value=\"[philg_quote_double_quotes $msg_id]\">
      <input type=submit value=\"Go\"></form>"

        set watchers [database_to_tcl_list $db "select first_names || ' ' || last_name from users u, ticket_email_alerts tea where u.user_id = tea.user_id and tea.msg_id = $msg_id"]
        if {![empty_string_p $watchers]} { 
            append users "<strong>Ticket watchers:</strong><ul><li>[join $watchers "<LI>"]</ul>"
        }
    }
    return $users
}




proc_doc export_ns_set_value {variable {form {}}} { 
    looks for variable in the given form ns_set and 
    returns value="foo" if it exists otherwise
    returns empty string.
    <p>
    uses ns_conn form by default.
} { 
    if {[empty_string_p $form]} { 
        set form [ns_conn form]
    }
    
    if {![empty_string_p $form]} { 
        set i [ns_set find $form $variable]
        if { $i > -1 } { 
            return "value=\"[philg_quote_double_quotes [ns_set value $form $i]]\""
        }
    }
    return {} 
}


ad_proc text_search_widget {
    {
        -required {} 
        -bad_p 0
        -post {}
        -size 16 
    }
    text prefix field_name n_fields 
} {
    generate a text search widget with joiners
} {

    set frag {}

    if { $bad_p } {
        append frag "<tr><td text=red>$text$required</td><td>"
    } else {
        append frag "<tr><td>$text$required</td><td>"
    }

    set i 0
    while {$i < $n_fields} {
        if {$n_fields < 2} { 
            set name "$prefix${field_name}"
        } else { 
            set name "$prefix${field_name}_$i"
        }
        append frag "\n<input type=text size=$size maxlength=100 name=\"$name\" [export_ns_set_value $name]>"

        incr i
        if { $i < $n_fields } {
            set name "$prefix${field_name}_j_[expr $i - 1]"
            set value [export_ns_set_value $name]
            set opt {<option value="and">AND</option><option value="or">OR</option><option value="and_not">AND NOT</option>}
            if {![empty_string_p $value]} { 
                regsub $value $opt "SELECTED $value" opt
            }
            append frag "\n<select name=\"$name\">$opt</select>"
        }
    }
    append frag "$post\n</td></tr>\n"
}

proc_doc ticket_query {form key field like_p case_insensitive_p} {
    build a subclause
} { 
    set join(and) and
    set join(and_not) {and not}
    set join(or) or

    set i 0
    set out {}
    set idx [ns_set find $form ${key}_$i]

    while { $idx > -1} {
        set compare [ns_set value $form $idx]
        
        if {![empty_string_p $compare]} {
            if {$case_insensitive_p} { 
                append out " lower($field) "
                if {$like_p} { 
                    append out "like '%[DoubleApos [string tolower $compare]]%' "
                } else { 
                    append out "= '[DoubleApos [string tolower $compare]]') "
                }
            } else { 
                append out " $field "
                if {$like_p} { 
                    append out "like '%[DoubleApos $compare]%' "
                } else { 
                    append out "= '[DoubleApos $compare]' "
                }
            } 
            set jidx [ns_set find $form ${key}_j_$i]
            incr i
            set idx [ns_set find $form ${key}_$i]
            if {$jidx > 0 && 
                ![empty_string_p [ns_set value $form $idx]]} {
                append out $join([ns_set value $form $jidx])
            }
        } else { 
            incr i
            set idx [ns_set find $form ${key}_$i]
        }
    }
    return $out
}

proc_doc collapse {list re} { 
    returns list with all entries that do not match re
    removed
} { 
    set out {} 
    foreach element $list { 
        if {[regexp $re $element]} { 
            lappend out $element
        }
    }
    return $out
}
        
proc_doc ticket_build_advs_query {} {
    build the query from the form
} { 
    set form [ns_conn form]
    if {[empty_string_p $form]} { 
        return {}
    }

    set out {}

    set field(advs_qs) {ti.one_line} 
    set field(advs_tt) {ti.one_line}
    set field(advs_pr) {ti.project_id}
    set field(advs_fa) {ti.domain_id} 
    set field(tc) {ti.posting_time}
    set field(tcl) {ti.closed_date}
    set field(tm) {ti.last_modified}
    set field(td) {ti.deadline}


    # text field queries
    foreach key {advs_qs advs_tt} { 
        set query [ticket_query $form $key $field($key) 1 1]        
        if {![empty_string_p $query]} { 
            lappend out $query
        }
    } 

    set msg_id [join [collapse [split [ns_set get $form {advs_ti}] {, }] {^[0-9]+$}] {,}]

    if {![empty_string_p $msg_id]} {  
        lappend out "ti.msg_id in ($msg_id)"
    }

    # build a list of code based multisearches
    set args [ticket_advs_multi_vars advs {pr fa type status priority severity source cause}]
    ad_page_variables $args
    foreach code $args { 
        if {[empty_string_p [lindex $code 1]]} { 
            lappend fields [lindex $code 0]
        }
        if {![info exists field([lindex $code 0])]} { 
            regsub {advs_} [lindex $code 0] {} code_name
            set field([lindex $code 0]) "ti.${code_name}_id"
        }
    }
    
    foreach key $fields { 
        if {![empty_string_p [set $key]]} { 
            lappend out "$field($key) in ([join [set $key] {,}])"
        }
    }

    # do the date comparisons 
    set sql_comp(le) "<="
    set sql_comp(ge) ">="
    foreach key {tc tm tcl td} { 
        foreach comp {le ge} { 
            set compare [ns_set get $form advs_$key$comp]
            if {![empty_string_p $compare]} { 
                lappend out "trunc($field($key)) $sql_comp($comp) '[DoubleApos $compare]'"
            }
        }
    }

    # the stupid email or last name compare 
    set prefix(advs_tcrat) {users} 
    set prefix(advs_tasto) {assigned_users}
    set prefix(advs_tclby) {closing_users}
    
    foreach key {advs_tcrat advs_tasto advs_tclby} {
        set compare [ns_set get $form $key]
        if {![empty_string_p $compare]} { 
            set compare "'%[DoubleApos [string tolower $compare]]%'"
            lappend out "lower($prefix($key).first_names || ' ' ||$prefix($key).last_name) like $compare or lower($prefix($key).email) like $compare"
        }
    }
    
    if {![empty_string_p $out]} { 
        return "([join $out ")\n   and ("]) "
    } 
    return {}
}
        

proc_doc ticket_advs_multi_vars {prefix codes} {
    generate a list suitable for ad_page_variables
} { 
    set args {}
    foreach code $codes { 
        lappend args [list ${prefix}_$code -multiple-list]
        lappend args [list ${prefix}_$code {}]
    }
    return $args
}

proc_doc ticket_advs_query_page_fragment {db} {
    make the advanced query page fragment
} { 
    set codes {type status priority severity cause}
    ad_page_variables [ticket_advs_multi_vars advs [concat {pr fa} $codes]]

    append out "<table><tr><th align=left bgcolor=\"c0c0c0\" colspan=2>&nbsp;Advanced Search</th></tr><tr><td>&nbsp;&nbsp;<input type=submit value=\"Search\"></td></tr>"

    # plainish text fields

    append out [text_search_widget -size 50 "Query string:" {} query_string 1]
    append out [text_search_widget "Ticket title:" advs_ tt 3]
    append out [text_search_widget -size 30 "Created by<br>(email or name):" advs_ tcrat 1]
    append out [text_search_widget -size 30 "Assigned to<br>(email or name):" advs_ tasto 1]
    append out [text_search_widget -size 30 "Closed by<br>(email or name):" advs_ tclby 1]
    append out [text_search_widget -size 30 -post {<em>&nbsp;(space separated list)</em>} "Ticket ID \#'s:" advs_ ti 1]

    # project/feature areas 
    append out "<tr><td colspan=2><table>"
    append out "<td align=left>Project</td><td align=left>Feature area</td></tr><tr>"
    set select [ad_db_select_widget -size 5 -multiple 1 -default $advs_pr $db "select title_long, project_id from ticket_projects where (end_date > sysdate or end_date is null) order by upper(title_long) asc" advs_pr]
    append out "<td>$select</td>"
    set select [ad_db_select_widget -size 5 -multiple 1 -default $advs_fa $db "select title_long, domain_id from ticket_domains where (end_date > sysdate or end_date is null) order by upper(title_long) asc" advs_fa]
    append out "<td>$select</td>"
    
    append out "</tr></table></td></tr>\n"

    # the codes select substable

    append out "<tr><td colspan=2><table>" 

    append out "<tr>"
    foreach code $codes { 
        append out "<td>$code</td>"
    }
    append out "<tr>"

    append out "<tr>"
    foreach code $codes { 
        append advs_$code {}
        set select [ad_db_select_widget -size 5 -multiple 1 -default [set advs_$code] $db "select code_long, code_id from ticket_codes_i where code_type = '$code' order by code_seq" advs_$code]
        append out "<td>$select</td>"
    }
    append out "<tr>"

    append out "</table></td></tr>"


    # dates subtable

    append out "<td colspan=2><table>"

    append out "<tr><td>Creation date:</td><td><table>"
    append out [text_search_widget -post {&nbsp;(<em>yyyy-mm-dd</em>)} "Greater than or equal to:" advs_ tcge 1]
    append out [text_search_widget -post {&nbsp;(<em>yyyy-mm-dd</em>)} "Less than or equal to:" advs_ tcle 1]
    append out "</table></td></tr>"

    append out "<tr><td>Modification date:</td><td><table>"
    append out [text_search_widget -post {&nbsp;(<em>yyyy-mm-dd</em>)} "Greater than or equal to:" advs_ tmge 1]
    append out [text_search_widget -post {&nbsp;(<em>yyyy-mm-dd</em>)} "Less than or equal to:" advs_ tmle 1]
    append out "</table></td></tr>"

    append out "<tr><td>Close date:</td><td><table>"
    append out [text_search_widget -post {&nbsp;(<em>yyyy-mm-dd</em>)} "Greater than or equal to:" advs_ tclge 1]
    append out [text_search_widget -post {&nbsp;(<em>yyyy-mm-dd</em>)} "Less than or equal to:" advs_ tclle 1]
    append out "</table></td></tr>"

    append out "<tr><td>Deadline:</td><td><table>"
    append out [text_search_widget -post {&nbsp;(<em>yyyy-mm-dd</em>)} "Greater than or equal to:" advs_ tdge 1]
    append out [text_search_widget -post {&nbsp;(<em>yyyy-mm-dd</em>)} "Less than or equal to:" advs_ tdle 1]
    append out "</table></td></tr>"

    append out "</table></td></tr>"

    append out "</table><blockquote><input type=submit value=Search></blockquote>" 

    return $out
}

proc_doc ticket_xrefs_display {db my_msg_id return_url} { 
    display the xref tickets with a link to unlink
} { 

    set selection [ns_db select $db "
 select to_ticket, from_ticket, one_line, to_ticket as view_ticket
 from ticket_xrefs, ticket_issues
 where  to_ticket = ticket_issues.msg_id and from_ticket=$my_msg_id
    UNION
 select to_ticket, from_ticket, one_line, from_ticket as view_ticket
 from ticket_xrefs, ticket_issues
 where  from_ticket = ticket_issues.msg_id and to_ticket=$my_msg_id"]

    append page "<br><strong>Related tickets:</strong><ul>"
    while {[ns_db getrow $db $selection]} {
        set_variables_after_query

        append page "<li>\#<a href=\"issue-view.tcl?msg_id=$view_ticket&[export_url_vars return_url]\">$view_ticket</a> $one_line
  &nbsp;&nbsp; (<a href=\"ticket-unlink.tcl?from_ticket=$from_ticket&to_ticket=$to_ticket&return_url=[ns_urlencode "[ns_conn url]?[export_ns_set_vars url]"]\">unlink</a>)"
    }
    append page "<form action=\"ticket-link.tcl\">Link ticket \#<input type=text maxlength=8 size=6 name=to_ticket><input type=hidden name=return_url value=\"[philg_quote_double_quotes "[ns_conn url]?[export_ns_set_vars url]"]\"><input type=hidden name=from_ticket value=\"$my_msg_id\"> &nbsp; 
    <input type=submit value=\"Link\">
    </form>"
    append page "</ul>"                  


    return $page
}


proc ticket_exclude_regexp re { 
    set form [ns_conn form]
    set nukes 0
    if { ![empty_string_p $form] } { 

        set size [ns_set size $form]

        for {set i 0} {$i < $size} {incr i} { 
            set key [ns_set key $form $i]
            if {[regexp $re $key]} {
                set nuke($key) 1
                incr nukes
            }
        }
    }
    if { $nukes } { 
        return [array names nuke]
    } else { 
        return {}
    }
}

proc_doc ticket_user_display {name email user_id {kind {}}} { 
    used to generate the username display -- here so that 
    it can be changed easily between displaying email 
    and pointing at /shared/community-member.tcl
    and /intranet/user-info.tcl
} { 
    if {[empty_string_p $kind]} { 
        set kind [ad_parameter TicketUserLink ticket intranet]
    }
    
    switch $kind { 
        intranet { 
            return "<a href=\"/intranet/users/view.tcl?user_id=$user_id\">$name</a>"
        }
        email { 
            return "<a href=\"mailto:$email\">$name</a>"
        }
        name { 
            return "$name"
        }
        public -
        default { 
            return "<a href=\"/shared/community-member.tcl?user_id=$user_id\">$name</a>"
        }
    }
}

proc_doc ticket_alert_manage {db user_id} { 
    generate a list of ticket watches with links to disable.
    
    mostly intended for /pvt/alerts.tcl
    and the settings screen.
} { 
    set selection [ns_db select $db "select
  tea.alert_id, tea.msg_id, tea.domain_id, tea.project_id, tea.active_p,
  ti.one_line, ti.status_long,
  tp.title_long as project_title, 
  td.title_long as domain_title 
 from ticket_email_alerts tea, ticket_issues ti, 
  ticket_projects tp, ticket_domains td 
 where tea.user_id = $user_id 
  and tea.msg_id = ti.msg_id (+) 
  and (tea.project_id = tp.project_id or ti.project_id = tp.project_id)
  and (tea.domain_id = td.domain_id or ti.domain_id = td.domain_id)"]
    
    set out "<h3>[ticket_system_name] alerts</h3><ul>\[ <a href=\"/ticket/ticket-alert-manage.tcl?what=enable_all&alert_id=0\">enable all</a>&nbsp;|&nbsp;<a href=\"/ticket/ticket-alert-manage.tcl?what=disable_all&alert_id=0\">disable all</a>&nbsp;|&nbsp;<a href=\"/ticket/ticket-alert-manage.tcl?what=delete_all&alert_id=0\">delete all</a> \]<br><br>"
    set counter 0
    set act(t) disable
    set act(f) enable

    set msg(t) {<font color=red>enabled</font>}
    set msg(f) {disabled}

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	incr counter
        
        if { [empty_string_p $msg_id]} { 
            append out "\n<li> All ticket in project $project_title: $domain_title"
        } else { 
            append out "\n<li> <a href=\"/ticket/issue-view.tcl?msg_id=$msg_id\">\#$msg_id $one_line</a> in <em>$project_title: $domain_title</em> $msg($active_p)"
        }
        append out " (<a href=\"/ticket/ticket-alert-manage.tcl?alert_id=$alert_id\&what=$act($active_p)\">$act($active_p)</a>&nbsp;|&nbsp;<a href=\"/ticket/ticket-alert-manage.tcl?alert_id=$alert_id\&what=delete\">remove</a>)"
    }
    if $counter { 
        append out {</ul>}
    } else { 
        set out {}
    }
    
    return $out
}
        

util_report_successful_library_load

















