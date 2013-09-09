# /tcl/ticket-defs.tcl
ad_library {
    Ticket tracker support routines.

    @author Original author unknown (Jeff Davis?)
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id ticket-defs.tcl,v 3.32.2.7 2000/09/22 01:34:04 kevin Exp
}

# 
# Routines for configuration support 
# 

proc_doc ticket_system_name {} {
    returns the ticket system name.
} { 
    return "Ticket Tracker"
}

#proc ticket_getdbhandle {} {
#   return [ns_db gethandle main]
#}

proc_doc ticket_mail_footer {} {
    Returns the footer associated with the ticket
} { 
    return [ad_parameter TicketMailFooter ticket "-- automatically sent from [ticket_system_name] --"]
}

proc_doc ticket_mail_send {addresses} {
    This will override the addresses if the parameter
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

proc_doc ticket_assignee_select { group_id user_id {default_message {-- None assigned --}} {variable {}}} {
    given a group_id and user_id generate a select 
    widget for choosing a new default user 
    to feed to ticket-assignments-update.tcl
} { 
    if {[empty_string_p $variable]} { 
        set variable assignee
    }
    set bind_vars [ad_tcl_vars_to_ns_set group_id]
    return [ad_db_select_widget -default $user_id  -hidden_if_one_db 1 \
	    -blank_if_no_db 1 -option_list [list [list {} $default_message]] \
	    -bind $bind_vars possible_assignees \
	    "select u.last_name || ', ' || u.first_names || ' (' || u.email || ')' as uname, u.user_id
from users u
where ad_group_member_p(u.user_id, :group_id) = 't'
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
        lappend out "<a href=\"ticket-code-set?msg_id=$msg_id&what=status&value=closed&action=comment&return_url=[ns_urlencode "[ns_conn url]?[export_ns_set_vars url]"]\">$comment($type)</a>"
    } 
    if {$where != "view" } {
        lappend out "<a href=\"/ticket/issue-view?msg_id=$msg_id&$return_url\">$view($type)</a>"
    }

    if {$where != "edit" } { 
        lappend out "<a href=\"/ticket/issue-new?msg_id=$msg_id&mode=full&$return_url\">$edit($type)</a>"
    } 
    if {$type == "list"} { 
        lappend out "<a href=\"ticket-move?msg_id=$msg_id&$return_url\">$move($type)</a>"
        #lappend out "<a href=\"issue-new?ascopy=1&msg_id=$msg_id&project_id=&$return_url\">$makecopy($type)</a>"
        lappend out "<a href=\"issue-audit?msg_id=$msg_id&$return_url\">$changes($type)</a>"
        lappend out "<a href=\"ticket-watch?msg_id=$msg_id&return_url=[ns_urlencode "[ns_conn url]?[export_ns_set_vars url]"]\">Watch this ticket (get email on all activity)</a><p>"
        
    } 

    # this is a huge mess.  fix later.  should just be data driven.
    if { $user_id == $ticket_user_id 
         && $user_id != $assigned_user_id } {
        if {$status_subclass == "approve"
            && $responsibility == "user" } {
            lappend out "<a href=\"ticket-code-set?msg_id=$msg_id&what=status&value=closed&action=approve&$return_url\">$approve($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$approve($type)</em>"
        }
        
        if {$status_subclass == "clarify"
            && $responsibility == "user" } { 
            lappend out "<a href=\"ticket-code-set?msg_id=$msg_id&what=status&value=open&action=clarify&$return_url\">$clarify($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$clarify($type)</em>"
        }
        if {$status_class == "active" 
            && $status_subclass != "approve"} { 
            lappend out "<a href=\"ticket-code-set?msg_id=$msg_id&what=status&value=closed&action=cancel&$return_url\">$cancel($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$cancel($type)</em>"
        }        
    }

    if {$user_id == $ticket_user_id || $user_id == $assigned_user_id} { 
        if { ($status_class == "closed" && $user_id == $ticket_user_id)
             || ($status_class == "defer" && $user_id == $assigned_user_id) } {
            lappend out "<a href=\"ticket-code-set?msg_id=$msg_id&what=status&value=open&action=reopen&$return_url\">$reopen($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$reopen($type)</em>"
        }
    }

    # assigned user actions
    if { $user_id == $assigned_user_id } {
        if {$status_class == "active" 
            && $status_subclass != "approve" } { 
            lappend out "<a href=\"ticket-code-set?msg_id=$msg_id&what=status&value=need%20def&action=needdef&$return_url\">$needdef($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$needdef($type)</em>"
        }

        if {$status_class == "active" 
            && $status_subclass != "approve" } { 
            lappend out "<a href=\"ticket-code-set?msg_id=$msg_id&what=status&value=defer&action=defer&$return_url\">$defer($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$defer($type)</em>"
        }

        if {$status_class == "active" 
            && $status_subclass != "approve" } { 
            lappend out "<a href=\"ticket-code-set?msg_id=$msg_id&what=status&value=Fix/AA&action=fixed&$return_url\">$fixed($type)</a>"
        } elseif { $type == "list" } { 
            lappend out "<em>$fixed($type)</em>"
        }
    } 
    
    if {$user_id == $ticket_user_id || $user_id == $assigned_user_id} { 
        if {$status_class == "active" } { 
            lappend out "<a href=\"ticket-code-set?msg_id=$msg_id&what=status&value=closed&action=close&$return_url\">$close($type)</a>"
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

ad_proc -private ticket_report {
    {-bind ""}
    statement_name sql view table_def
} { 
    generate a report.
} { 
    set i 0
    set html {} 
    db_foreach ticket_report_query $sql -bind $bind {
        if {![info exists seen($msg_id)]} { 
            set seen($msg_id) 1
            set order($i) $msg_id
            set line($msg_id) "<p><strong><a href=\"issue-view?msg_id=$msg_id\">\#$msg_id $one_line</a></strong><br>Project: <strong>$project_title_long</strong> Feature Area: <strong>$domain_title_long</strong> Status: <strong>$status_long</strong> Creation Date: <strong>$creation_mdy</strong> Severity: <strong>$severity_long</strong><br>"
            if { $view == "full_report" } {
                append chtml($msg_id) "<blockquote>"
                if { $html_p == "f" } { 
                    append chtml($msg_id) [util_convert_plaintext_to_html $message]
                } else { 
                    append chtml($msg_id) $message
                }
                append chtml($msg_id) "<br>-- $user_name &lt;<a href=\"mailto:$email\">$email</a>&gt;</blockquote>"

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
    # messages
    if {$view == "full_report"} {
        db_foreach get_ticket_comment "
  select gc.on_what_id, gc.comment_id, gc.client_file_name,
    gc.file_type, gc.original_width, gc.original_height, gc.caption, gc.content, gc.html_p, 
    u.last_name, u.first_names, u.email, u.user_id, 
    to_char(comment_date, 'Month, DD YYYY HH:MI AM') as comment_date_long
  from general_comments gc, users u
  where on_which_table = 'ticket_issues' 
    and u.user_id = gc.user_id 
    and on_what_id in ([join [array names seen] {,}]) 
  order by comment_date asc" {
    
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

proc_doc ticket_feedback_link {{text {Feedback}} {module_key ""} } {
    returns the html for a link into the ticket system for 
    page feedback
    <p>
    <ul><li><i>module_key</i> is the primary key for the module in the acs_modules table.
    If no module key is supplied, we see if a module has been registered to the URL that has
    been called.
    <li><i>text</i> is the text to display as the link.
    </ul>
    <p>
    We need to map module_key to project_id to get this to work properly.
} {
    set ticket_server [ad_parameter TicketServer module-manager "www.arsdigita.com"]
    if ![empty_string_p $ticket_server] {
	set ticket_server "http://$ticket_server"
    }

    if [empty_string_p $module_key] {
	set module_key ticket
#[ad_module_name_from_url]
    }

    return "<a href=\"$ticket_server/ticket/issue-new?mapping_key=[ns_urlencode $module_key]&from_host=[ns_urlencode [ns_conn location]]&from_url=[ns_urlencode [ns_conn url]]&fq_len=[string length [ns_conn query]]&from_query=[ns_urlencode [ns_conn query]]\">$text</a>"
}

proc_doc ticket_page_link {{text {Page ticket}}} {
    returns the html for a link into the ticket system for 
    page tickets
    <p>
    Note that this function assumes that project_id 0 is the "Incoming" project
} {
    return "<a href=\"/ticket/issue-new?project_id=0&from_host=[ns_urlencode [ns_conn location]]&from_url=[ns_urlencode [ns_conn url]]&fq_len=[string length [ns_conn query]]&from_query=[ns_urlencode [ns_conn query]]\">$text</a>"
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

proc_doc ticket_user_contributions {user_id purpose} {Returns list items, one for each bboard posting} {
    if { $purpose != "site_admin" } {
	return [list]
    } 

    if {![db_0or1row tickets_for_one_user "
    select count(tia.msg_id) as total,
    	   sum(decode(status_class,'closed',1,0)) as closed,
    	   sum(decode(status_class,'closed',0,'defer',0,NULL,0,1)) as open,
    	   sum(decode(status_class,'defer',1,0)) as deferred,
    	   max(last_modified) as lastmod,
    	   min(posting_time) as oldest
    from   ticket_issues ti, ticket_issue_assignments tia
    where  tia.user_id = :user_id
    and    ti.msg_id = tia.msg_id"]} {

	return [list]
    }

    if { $total == 0 } {
	return [list]
    }

    set items "<li>Total tickets:  $total ($closed closed; $open open; $deferred deferred)
 <li>Last modification:  [util_AnsiDatetoPrettyDate $lastmod]
 <li>Oldest:  [util_AnsiDatetoPrettyDate $oldest]"
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

proc_doc ticket_new_stuff {since_when only_from_new_users_p purpose} {
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
 where posting_time > :since_when
 and ti.user_id = ut.user_id"
    set result_items {}

    db_foreach info_about_new_tickets $query {
 	append result_items "<li><a href=\"/ticket/issue-new?[export_url_vars msg_id]\">$one_line</a> by <a href=\"/admin/users/one?user_id=$user_id\">$user_name</a> (<a href=\"mailto:$email\">$email</a>)"
    } if_some_rows {
	return "<ul>\n\n$result_items\n</ul>\n"
    } if_no_rows {
 	return ""
    }
}

# returns 1 if current user is in admin group for ticket module
proc ticket_user_admin_p {} {
    set user_id [ad_verify_and_get_user_id]
    return [ad_administration_group_member ticket "" $user_id]
}

# return the GID of the ticket admin group
proc ticket_admin_group {} {
    return [ad_administration_group_id "ticket" ""]
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

proc ticket_explain_security { user_id } {

    set page_title "Limited Access to Ticket Tracker"

    set whole_page "[ad_header $page_title]
    <h2>$page_title</h2>
    As one of our customers, your access to the ticket tracker is
    limited to your own projects.  Please choose one from the following:
    <ul>"

    # figure out what projects this customer is allowed to access
    db_foreach allowed_projects_for_customer "select tp.title, tp.project_id
    from ticket_projects tp, im_projects ip, user_group_map ugm
    where ugm.user_id = :user_id
    and ip.group_id = ugm.group_id
    and tp.group_id = ip.group_id" {

	append whole_page "<li><a href=\"/ticket/?project_id=$project_id\">$title</a>\n"
    } if_no_rows {
	append whole_page "<li><i>You currently do not belong to any projects.</i>"
    }

    append whole_page "</ul> [ad_footer]"

    doc_return  200 text/html $whole_page
}


# Check for the user cookie, redirect if not found.

# luke@arsdigita.com 6/7/2000 make it more secure if we have intranet groups set up

proc ticket_security_checks {args why} {

    set user_id [ad_verify_and_get_user_id]
    if {$user_id == 0} {
	ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    } 

    if { [im_enabled_p] } {
	
	if { [im_user_is_authorized_p $user_id] } {
	    # employees have full access
	    db_release_unused_handles
	    return filter_ok
	}
	if { [im_user_is_customer_p $user_id] } {
	    # customers may only access their own projects
	    # how do we check the custom settings??
	    set form [ns_getform]
	    set project_id ""
	    if { ![empty_string_p $form] && ![empty_string_p [ns_set get $form "msg_id"]]} {
		set msg_id [ns_set get $form "msg_id"]
		db_1row project_id_for_one_msg "
		select project_id 
		from ticket_issues_i
		where msg_id= :msg_id"
	    }
	    if { [empty_string_p $project_id] && ![empty_string_p $form] && ![empty_string_p [ns_set get $form "project_id"]] } {
		set project_id [ns_set get $form "project_id"]
	    }
	    if { [empty_string_p $project_id] } {
		ticket_explain_security $user_id
		db_release_unused_handles
		return filter_return
	    }
	    set customer_id [db_string -default "" \
		    customer_id_for_one_project \
		    "select ip.customer_id
	    from ticket_projects tp, im_projects ip
	    where tp.project_id = :project_id
	    and tp.group_id = ip.group_id"]
	    if { ![empty_string_p $customer_id] && [db_string user_on_project \
		    "select decode(ad_group_member_p(:user_id, :customer_id), 't', 1, 0) from dual" ] } {
		db_release_unused_handles
		return filter_ok
	    }
	    ticket_explain_security $user_id
	    db_release_unused_handles
	    return filter_return
	}
	db_release_unused_handles
	# non-customers are out of luck
	ad_return_forbidden "Access Denied" "Your account does not have access to this page."
	return filter_return
    }
    
    return filter_ok	
}

# Checks if user is logged in, AND is a member of the ticket admin group
proc ticket_security_checks_admin {args why} {
    set user_id [ad_verify_and_get_user_id]
    if {$user_id == 0} {
	ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    } 
    
    if {![ticket_user_admin_p]} {
        db_release_unused_handles
	ad_return_error "Access Denied" "Your account does not have access to this page."
	return filter_return
    }
    
    db_release_unused_handles

    return filter_ok
}

proc ticket_reply_email_addr {{msg_id ""} {user_id 0}} {
    if {[empty_string_p $msg_id]} { 
        return [ad_parameter TicketReplyEmail ticket]
    } else { 
        return "ticket-$msg_id-$user_id@[ad_parameter TicketReplyHost ticket "nowhere.tv"]"        
    }
}

proc_doc ticket_notify {what msg_id subject body {excluded_users {}}} { 
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
                set sql "select
 u.email as notify_email, u.first_names || ' ' || u.last_name as user_name,
   u.user_id as notify_user_id
 from users_alertable u, ticket_email_alerts tea, ticket_issues ti
 where  u.user_id = tea.user_id 
   and ti.msg_id = :msg_id 
   and (tea.msg_id = ti.msg_id
        or (tea.domain_id = ti.domain_id and tea.project_id is null)
        or (tea.domain_id is null and tea.project_id = ti.project_id)
        or (tea.domain_id = ti.domain_id and tea.project_id = ti.project_id))"
                set is_a "watcher"
            }
            
            admin { 
                # set all admins -- do not spam if notify_admin_p is false.
                set query 1
                set sql "select
  u.email as notify_email,
  u.first_names || ' ' || u.last_name as user_name,
   u.user_id as notify_user_id
 from users_alertable u,
  ticket_issues t, 
  ticket_domains td, 
  ticket_projects tp, 
  user_group_map ugm
 where  u.user_id = ugm.user_id 
  and t.msg_id = :msg_id 
  and td.domain_id = t.domain_id 
  and ugm.group_id = td.group_id 
  and ugm.role = 'administrator'
  and td.notify_admin_p = 't'"
                set is_a "admin"
            }

            assignee { 
                # set all assigned users 
                set query 1
                set sql "select
 u.email as notify_email, u.first_names || ' ' || u.last_name as user_name, 
   u.user_id as notify_user_id
 from users_alertable u, ticket_issue_assignments tia, ticket_issues t
 where tia.msg_id = :msg_id
 and u.user_id = tia.user_id and t.msg_id = :msg_id and tia.msg_id = t.msg_id"
                set is_a "assignee"
            }
            
            submitter { 
                if {[lsearch -exact {new_ticket} $what] < 0} { 
                    set query 1
                    set sql "select
 u.email as notify_email, u.first_names || ' ' || u.last_name as user_name,
   u.user_id as notify_user_id
 from users_alertable u, ticket_issues t where t.user_id = u.user_id and t.msg_id = :msg_id"
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
            db_foreach ticket_notify_query $sql {
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
                        [ticket_mail_send_body $who "$body\n\n$send_to\nManage via [ad_url]/ticket/issue-view.tcl?msg_id=$msg_id"] \
                        $extra_headers} errmsg]} { 
		    append send_to_html "Error for $who<pre>$errmsg</pre>"
		}
	    }
    
    append send_to_html "Subject: <strong>[ns_quotehtml $subject]</strong><pre>[ns_quotehtml $body]</pre>\nManage via <a href=\"[ad_url]/ticket/issue-view?msg_id=$msg_id\">/ticket/issue-view.tcl?msg_id=$msg_id</a>"
    return $send_to_html
}

proc_doc ticket_context context {
    given a list this generates the ticket context bar
} { 
    set context_last [expr [llength $context] - 1]
    set context [lreplace $context $context_last end [lindex [lindex $context $context_last] 1]]
    return [eval ad_context_bar_ws_or_index $context]
}

proc_doc ticket_assigned_users {project_id domain_id domain_group_id msg_id one_line my_return_url {admin_p 0} } { 
    generate the list of assigned users with remove and picklist 
    to add more if an admin for the group to which the ticket is assigned
} { 
    set users {}
    set pre {<strong>Assigned users:</strong><ul><li>}

    db_foreach assigned_users "select
  last_name || ', ' || first_names as assigned_name,
  u.email as assigned_email,
  u.user_id as assigned_user_id
  from users u, ticket_issue_assignments tia where tia.msg_id = :msg_id and u.user_id = tia.user_id
  order by upper(last_name) asc, upper(first_names) asc" {

        append users "$pre [ticket_user_display $assigned_name $assigned_email $assigned_user_id ] &lt<a href=\"mailto:$assigned_email\">$assigned_email</a>&gt;"
        if { $admin_p } { 
            append users " (<a href=\"/ticket/ticket-remove-assignment?msg_id=$msg_id&user_id=$assigned_user_id&$my_return_url\">remove</a>)"
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
        append users "<form method=get action=\"/ticket/ticket-update-assignment\">
      Assign to: [ticket_assignee_select $domain_group_id {} {-- Remove all assignees --}]
	[export_form_vars project_id domain_id one_line msg_id]
      <input type=hidden name=return_url value=\"[philg_quote_double_quotes "[ns_conn url]?[export_ns_set_vars url]"]\">
      <input type=submit value=\"Go\"></form>"

    }

    set watchers [db_list ticket_watchers "select first_names || ' ' || last_name from users u, ticket_email_alerts tea where u.user_id = tea.user_id and tea.msg_id = :msg_id"]
    if {![empty_string_p $watchers]} { 
        append users "<strong>Ticket watchers:</strong><ul><li>[join $watchers "<LI>"]</ul>"
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

proc_doc ticket_advs_query_page_fragment {} {
    make the advanced query page fragment
} { 
    set codes {type status priority severity cause}
    # I may have to kill someone for this.
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
    set select [ad_db_select_widget -size 5 -multiple 1 -default $advs_pr \
	    project_choices "select title_long, project_id from ticket_projects where (end_date > sysdate or end_date is null) order by upper(title_long) asc" advs_pr]
    append out "<td>$select</td>"
    set select [ad_db_select_widget -size 5 -multiple 1 -default $advs_fa \
	    domain_choices "select title_long, domain_id from ticket_domains where (end_date > sysdate or end_date is null) order by upper(title_long) asc" advs_fa]
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
	set bind_vars [ad_tcl_vars_to_ns_set code]
        set select [ad_db_select_widget -size 5 -multiple 1 \
		-default [set advs_$code] -bind $bind_vars \
		ticket_codes "select code_long, code_id from ticket_codes_i where code_type = '$code' order by code_seq" advs_$code]
	ns_set free $bind_vars
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

proc_doc ticket_xrefs_display {my_msg_id return_url} { 
    display the xref tickets with a link to unlink
} { 

    append page "<br><strong>Related tickets:</strong><ul>"

    db_foreach xref_info "
 select to_ticket, from_ticket, one_line, to_ticket as view_ticket
 from ticket_xrefs, ticket_issues
 where  to_ticket = ticket_issues.msg_id and from_ticket=$my_msg_id
    UNION
 select to_ticket, from_ticket, one_line, from_ticket as view_ticket
 from ticket_xrefs, ticket_issues
 where  from_ticket = ticket_issues.msg_id and to_ticket=:my_msg_id" {

        append page "<li>\#<a href=\"issue-view?msg_id=$view_ticket&[export_url_vars return_url]\">$view_ticket</a> $one_line
  &nbsp;&nbsp; (<a href=\"ticket-unlink?from_ticket=$from_ticket&to_ticket=$to_ticket&return_url=[ns_urlencode "[ns_conn url]?[export_ns_set_vars url]"]\">unlink</a>)"
    }

    append page "<form action=\"ticket-link\">Link ticket \#<input type=text maxlength=8 size=6 name=to_ticket><input type=hidden name=return_url value=\"[philg_quote_double_quotes "[ns_conn url]?[export_ns_set_vars url]"]\"><input type=hidden name=from_ticket value=\"$my_msg_id\"> &nbsp; 
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
            return "<a href=\"/intranet/users/view?user_id=$user_id\">$name</a>"
        }
        admin { 
            return "<a href=\"/admin/users/one?user_id=$user_id\">$name</a>"
        }
        email { 
            return "<a href=\"mailto:$email\">$name</a>"
        }
        name { 
            return "$name"
        }
        public -
        default { 
            return "<a href=\"/shared/community-member?user_id=$user_id\">$name</a>"
        }
    }
}

ad_proc ticket_alert_manage {user_id} { 
    Generate a list of ticket watches with links to disable.
    
    mostly intended for /pvt/alerts.tcl
    and the settings screen.
} { 
    set out "<h3>[ticket_system_name] alerts</h3><ul>\[ <a href=\"/ticket/ticket-alert-manage?what=enable_all&alert_id=0\">enable all</a>&nbsp;|&nbsp;<a href=\"/ticket/ticket-alert-manage?what=disable_all&alert_id=0\">disable all</a>&nbsp;|&nbsp;<a href=\"/ticket/ticket-alert-manage?what=delete_all&alert_id=0\">delete all</a> \]<br><br>"
    set no_rows_p 0
    set act(t) disable
    set act(f) enable

    set msg(t) {<font color=red>enabled</font>}
    set msg(f) {disabled}

    db_foreach ticket_alerts_for_one_user {
	select tea.alert_id, tea.msg_id, tea.domain_id, tea.project_id, tea.active_p,
	ti.one_line, ti.status_long,
	tp.title_long as project_title, 
	td.title_long as domain_title 
	from ticket_email_alerts tea, ticket_issues ti, 
	ticket_projects tp, ticket_domains td 
	where tea.user_id = :user_id 
	and tea.msg_id = ti.msg_id (+) 
	and (tea.project_id = tp.project_id or ti.project_id = tp.project_id)
	and (tea.domain_id = td.domain_id or ti.domain_id = td.domain_id)
    } {        
        if { [empty_string_p $msg_id]} { 
            append out "\n<li> All ticket in project $project_title: $domain_title"
        } else { 
            append out "\n<li> <a href=\"/ticket/issue-view?msg_id=$msg_id\">\#$msg_id $one_line</a> in <em>$project_title: $domain_title</em> $msg($active_p)"
        }
        append out " (<a href=\"/ticket/ticket-alert-manage?alert_id=$alert_id\&what=$act($active_p)\">$act($active_p)</a>&nbsp;|&nbsp;<a href=\"/ticket/ticket-alert-manage?alert_id=$alert_id\&what=delete\">remove</a>)"
    } if_no_rows { 
        set no_rows_p 1
	set out {}
    }
    if { !$no_rows_p } {
	append out "</ul>"
    }
    return $out
}
        

ad_proc ticket_group_pick_widget {
    { 
        -return_url {/ticket/admin} 
    }
    GS.group_search GS.group_type_restrict target
} { 
    generate the group pick widget
} { 
    set out {}

    if {![empty_string_p ${GS.group_search}]} { 

        set match "%[string tolower [string trim ${GS.group_search}]]%"
	
        set query "select user_groups.group_name as group_name,
 nvl(user_group_parent.group_name, user_groups.group_type) as group_type,
 user_groups.group_id
 from user_groups, user_groups user_group_parent
 where user_groups.parent_group_id = user_group_parent.group_id (+)
 and user_groups.approved_p = 't' and lower(user_groups.group_name) like :match"

        if {![empty_string_p ${GS.group_type_restrict}]} { 
            append query " and user_groups.group_type = :GS.group_type_restrict"
        }

        append query " order by lower(nvl(user_group_parent.group_name, user_groups.group_type)), lower(group_name)"
        
        db_foreach groups $query {
            
            if {[empty_string_p $out]} { 
                append out "<strong>$group_type</strong><ul>"
            } elseif {[string compare $last_group_type $group_type] != 0} { 
                append out "</ul>\n<strong>$group_type</strong>\n<ul>"
            }
            
            append out "<li> <a href=\"$target$group_id\">$group_name</a>"
            set last_group_type $group_type

        } if_some_rows {
            append out "</ul>"
        } if_no_rows { 
            set out "<em>no matching groups</em>"
        }

    }

    append out "<form method=post>
 Group name matching: <input type=text maxwidth=60 name=GS.group_search [export_form_value GS.group_search]> Group type:
 [ad_db_select_widget -default ${GS.group_type_restrict} -option_list {{{} {-- All Groups --}}} group_types "select pretty_plural, group_type from user_group_types order by pretty_plural" GS.group_type_restrict]
   [export_ns_set_vars form [ticket_exclude_regexp {^GS.}]]
 </form>"
    
    return $out
}

ad_proc bool_table_prompt {
    {
        -span {}
    } 
    prompt name value
} { 
    generate a boolean prompt
} {
    if {![empty_string_p $span]} { 
        set html "<tr><td colspan=$span><strong>$prompt</strong>&nbsp;"
    } else { 
        set html "<tr><th align=left>$prompt</th><td>"
    }

    if {$value == "t"} {
        append html "<input type=radio name=$name value=t CHECKED> Yes<input type=radio name=$name value=f> No"
    } else {  
        append html "<input type=radio name=$name value=t> Yes<input type=radio name=$name value=f CHECKED> No"
    }
    append html "</td>\n</tr>\n\n"

    return $html 
}
    
##Follow naming convention of the file, ticket_create
ad_proc ticket_create {
    {
        -msg_html plain
        -new_msg_id {}
        -public_p t
        -notify_p t 
        -severity_id null
        -priority_id null
        -cause_id null
        -status_id null
        -source_id null
        -type_id null
        -assignee {}
        -deadline null
        -from_url null
        -from_query null
        -from_project null
        -from_host null
        -from_ip null
        -from_user_agent null
        -version null
        -code_set ad
    }
    user_id project_id domain_id one_line message 
} {
    generate a new ticket and take all standard actions
} {
    ############################################################
    ##Setup the defaults
    ############################################################
    ##Generate good values for each code if it doesn't exist
    if {[string compare $status_id null] == 0} {
        set status_id [db_string status_code "select code_id as status_id from ticket_codes_i where code = 'open' and code_type = 'status'"]
    }
    set codes {severity priority type cause}
    foreach code $codes {
        set code_id "${code}_id"
        if {[string compare [set $code_id] null] == 0} {
            set where_clause "code_type = ':code' and code_set = ':code_set'"
            set ret [db_string -default "" codes "
            select code_id from ticket_codes 
	    where $where_clause 
	    and code_seq = (select min(code_seq) from ticket_codes 
	                    where $where_clause) and rownum = 1" ]
            if {![empty_string_p $ret]} {
                set $code_id $ret
            }
        }
    }
    ## assignee
    if {[empty_string_p $assignee]} {
        set assignee [db_string default_assignee "
	select tm.default_assignee from ticket_domain_project_map tm 
	where tm.project_id = :project_id 
	and tm.domain_id = :domain_id" -default ""]
        ##What do we do if we don't get anything here????
    }

    if {[empty_string_p $new_msg_id]} {
        set new_msg_id [db_string next_msg_id "select ticket_issue_id_sequence.nextval from dual"]
    }

    db_1row some_stuff "select to_char(sysdate,'Month, DD YYYY ') || sysdate as when_saved, email, first_names || ' ' || last_name as username from users where user_id = :user_id"
    ##########################################################
    ## Do DB inserts into general comments/ticket_issues_i
    ##########################################################
    set indexed_stuff "TR\#$new_msg_id\n$email\n$username\n$when_saved\n$message"
    db_transaction {
        set comment_id [db_string next_comment_id "
        select general_comment_id_sequence.nextval from dual"]
        if { $msg_html == "pre" } {
            regsub "\[ \012\015\]+\$" $message {} message
            set message "<pre>[ns_quotehtml $message]</pre>"
            set html_p t
        } elseif { $msg_html == "html" } { 
            set html_p t
        } else { 
            set html_p f
        }
        ad_general_comment_add $comment_id {ticket_issues_i} $new_msg_id \
                "\#$new_msg_id $one_line" $message $user_id [ns_conn peeraddr] {t} \
                $html_p $one_line

        # create the ticket
        db_dml ticket_insert "insert into ticket_issues_i
        (msg_id, project_id, version, domain_id, user_id, one_line,
        comment_id, ticket_type_id, priority_id, severity_id, source_id, 
	cause_id, status_id, posting_time, deadline, public_p, notify_p, 
        from_host, from_url, from_query, from_project, from_ip, 
	from_user_agent, last_modified, last_modifying_user, 
	modified_ip_address
        ) values (
        :new_msg_id,:project_id,:version,:domain_id, :user_id,:one_line,
        :comment_id, :type_id, :priority_id, :severity_id, :source_id, 
	:cause_id, :status_id, sysdate, :deadline, :public_p, 
	:notify_p, :from_host, :from_url, :from_query, :from_project, :from_ip,
        :from_user_agent,sysdate, :user_id, '[DoubleApos [ns_conn peeraddr]]')"

        if { ![empty_string_p $assignee]} { 
            db_dml assignment_insert "
	    insert into ticket_issue_assignments 
	    (msg_id, user_id, active_p)
	    values 
	    (:new_msg_id, :assignee, 't')" 
        }

        db_dml index_insert "
	insert into ticket_index 
	(msg_id, indexed_stuff, last_modified)
	values 
	($new_msg_id, empty_clob(), sysdate) 
	returning indexed_stuff into :1" -clob_files [list $indexed_stuff]
    } on_error {
        # something went a bit wrong during the insert
        error "<li>Here was the bad news from the database:
               <pre>$errmsg</pre>"
    }
    ##############################
    ##Now send out some email
    ##############################
    set returned_text ""
    if { $notify_p == "t"} {

        db_0or1row get_info_for_email "
	select td.title_long as domain_title, 
	       tp.title_long as project_title, 
	       priority_long, 
	       status_long, 
	       one_line as one_line 
	from   ticket_issues ti, 
	       ticket_domains td, 
	       ticket_projects tp 
	where  msg_id = :new_msg_id 
	and    td.domain_id = ti.domain_id 
	and    tp.project_id = ti.project_id" 

        set status_msg "STATUS: $status_long"
        set body "

ACTION BY: $username ($email)
PRIORITY: $priority_long  $status_msg

----------------------------------------
Ticket #$new_msg_id $one_line

"
        
        if {$msg_html == "plain" } { 
            append body [wrap_string $message 80]
        } else { 
            append body [util_striphtml $message]
        }
        append body "\n\nProject $project_title - $domain_title\n"
        append returned_text [ticket_notify new_ticket $new_msg_id $one_line $body]
    } 
    return $returned_text
}    

