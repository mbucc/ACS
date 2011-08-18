# $Id: issue-new-2.tcl,v 3.9 2000/03/08 13:13:45 davis Exp $
ad_page_variables {
    project_id domain_id one_line message msg_html 
    {new_msg_id {}} {msg_id {}} {comment_id 0}
    {public_p t} {notify_p t} 

    {ticket_type_id null} {severity_id null} {priority_id null} 
    {cause_id null} {source_id null} {status_id null}

    {ColValue.deadline.day {}}
    {project_deadline null} 

    {from_url null} {from_query null} {from_project null}
    {from_host null} {from_ip null} {from_user_agent null}

    {assignee {}}

    {return_url {/ticket/}}
    {ticket_user_id {}}
    {ascopy 0} 
    {old_status_long {}}
    {old_status_id {}}
    {status_message {}}
    {status_msg_html {}}
    {didsubmit {}}
    {mode {}}
}

set scope public

if {[empty_string_p $mode]} {
    unset mode
}

if {![empty_string_p ${ColValue.deadline.day}]} { 
    if {[catch {set deadline [validate_ad_dateentrywidget deadline deadline [ns_conn form]]} errmsg]} { 
        ad_return_complaint 1 "<LI> Bad explicit deadline: $errmsg"
        return
    }
} else { 
    set deadline null
}


set db [ns_db gethandle]

set user_id [ad_get_user_id]

if {[empty_string_p $ticket_user_id]} {
    set ticket_user_id $user_id
}

if {[empty_string_p $old_status_long]} {
    set old_status_long undefined
}

# check input
set exception_text ""
set exception_count 0

set pretty_name(ticket_type_id) "Type"
set pretty_name(severity_id) "Severity"
set pretty_name(priority_id) "Priority"
set pretty_name(cause_id) "Cause"
set pretty_name(source_id) "Source"
set pretty_name(status_id) "Status"
set pretty_name(project_id) "Project"
set pretty_name(domain_id) "Feature Area"
set pretty_name(new_msg_id) "new_msg_id \[Internal Error - Please report\]"
set pretty_name(msg_id) "msg_id \[Internal Error - Please report\]"
set pretty_name(ticket_user_id) "ticket_user_id \[Internal Error - Please report\]"
set pretty_name(ascopy) "ascopy flag \[Internal Error - Please report\]"

foreach field [array names pretty_name] {
    if {![regexp {(null|^[0-9]*$)} [set $field]]} { 
        incr exception_count
        append exception_text "<li> You must specify the $pretty_name($field)."
    } 
}

if {!$ascopy && ![empty_string_p $msg_id] && ![empty_string_p $new_msg_id]} {
    incr exception_count
    append exception_text "<li>Internal: cannot have msg_id and new_msg_id"
} elseif {[empty_string_p $msg_id] && [empty_string_p $new_msg_id]} { 
    incr exception_count
    append exception_text "<li>Internal: Must have msg_id or new_msg_id set"
}

if {[empty_string_p $one_line]} {
    incr exception_count
    append exception_text "<li>You must provide a subject.\n"
} else {
    if { [empty_string_p $message] } {
        set message $one_line
    }
}

if {$exception_count == 0} {
    if {[catch {set selection [ns_db 1row $db "select to_char(sysdate,'Month, DD YYYY ') || sysdate as when_saved, email, first_names || ' ' || last_name as username from users where user_id = $user_id"]} msg]} { 
        incr exception_count
        append exception_text "<li>I was unable to look up your user id.<pre>$msg</pre>"
    } else { 
        set_variables_after_query
    }
}

if {$exception_count == 0} {
    if {[catch {set selection [ns_db 1row $db "select title_long, version from ticket_projects where project_id = $project_id"]} msg]} { 
        incr exception_count
        append exception_text "<li>I was unable to look up your project id.<pre>$msg</pre>"
    } else {
        set_variables_after_query
    }
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

# NEED TO FIGURE OUT HOW TO HANDLE WHEN BOTH SET (I think need to track named deadlines seperately).
if { ([empty_string_p $deadline] || $deadline == "null")
     && ($project_deadline != "null" && $project_deadline != "0" ) } { 
    set deadline $project_deadline
}

if {![empty_string_p $new_msg_id]} { 
    set selection [ns_db 0or1row $db "select priority_long, status_long, one_line as old_one_line from ticket_issues where msg_id = $new_msg_id"]
    if {![empty_string_p $selection]} { 
        set_variables_after_query
    }
}

if { $ascopy || ![empty_string_p $new_msg_id] } {
    if {[info exists old_one_line]} {
        ns_return 200 text/html "[ad_header "Duplicate ID in database"]\n<H3>Ticket \"\#$new_msg_id - $old_one_line\" already exists in the database.</H3>
        [ticket_context [list [list $return_url {Ticket Tracker}] [list {} {Duplicate ID found}]]]<hr>
<ul> 
  <LI>If you are sure this is a new ticket you can <a href=\"[ns_conn url]?[export_ns_set_vars url new_msg_id]&new_msg_id=[database_to_tcl_string $db "select ticket_issue_id_sequence.nextval from dual"]\">resubmit it</a>.
  <li>If you double clicked you can <a href=\"$return_url\">return to the main screen</a>.
        </ul></font>[ad_footer]"
        return

    }

    if {! $ascopy } {
        # set directly from submitter.
        set from_user_agent [ns_set get [ns_conn headers] {User-Agent}]
        set from_ip [ns_conn peeraddr]
    } 
        

    set indexed_stuff "TR\#$new_msg_id\n$email\n$username\n$when_saved\n$message"
    util_dbq -null_is_null_p t {version one_line public_p notify_p 
        from_url from_query from_host from_project deadline from_ip from_user_agent}

    with_transaction $db {
        set comment_id [database_to_tcl_string $db "select general_comment_id_sequence.nextval from dual"]
        if { $msg_html == "pre" } {
            regsub "\[ \012\015\]+\$" $message {} message
            set message "<pre>[ns_quotehtml $message]</pre>"
            set html_p t
        } elseif { $msg_html == "html" } { 
            set html_p t
        } else { 
            set html_p f
        }
        ad_general_comment_add $db $comment_id {ticket_issues_i} $new_msg_id "\#$new_msg_id $one_line" $message $ticket_user_id [ns_conn peeraddr] {t} $html_p $one_line

        # create the ticket
        ns_db dml $db "insert into ticket_issues_i
    (msg_id, project_id, version, domain_id, user_id, one_line,
     comment_id,
     ticket_type_id, priority_id, severity_id, source_id, cause_id, status_id,
     posting_time, deadline, public_p, notify_p, 
     from_host, from_url, from_query, from_project, from_ip, from_user_agent, 
     last_modified, last_modifying_user, modified_ip_address
    ) values (
     $new_msg_id,$project_id,$DBQversion,$domain_id, $ticket_user_id,$DBQone_line,
     $comment_id,
     $ticket_type_id, $priority_id, $severity_id, $source_id, $cause_id, $status_id,
     sysdate, $DBQdeadline, $DBQpublic_p, $DBQnotify_p, 
     $DBQfrom_host, $DBQfrom_url, $DBQfrom_query, $DBQfrom_project, $DBQfrom_ip, $DBQfrom_user_agent, 
     sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')"

        if { ![empty_string_p $assignee]} { 
            ns_db dml $db "insert into ticket_issue_assignments (msg_id, user_id, active_p) values ($new_msg_id, $assignee, 't')"
        }

        ns_ora clob_dml $db "insert into ticket_index (msg_id, indexed_stuff, last_modified
 ) values ($new_msg_id, empty_clob(), sysdate) returning indexed_stuff into :1" $indexed_stuff
        if { $ascopy } {
            ns_db dml $db "insert into ticket_xrefs values ($msg_id, $new_msg_id)"
        }
} {
        # something went a bit wrong during the insert
        ad_return_complaint 1 "<li>Here was the bad news from the database:
 <pre>$errmsg</pre>"
        return -code return
    }
} else { 
    # msg_id so do update instead

    # first see if we need a comment for this change 
    if { [string compare $status_id $old_status_id] != 0} { 
        set status_long [database_to_tcl_string $db "select code_long from ticket_codes_i where code_id = $status_id"]
        
        
        if { [empty_string_p $status_message] } {

            ReturnHeaders 

        ns_write "[ad_header "Status change \#$msg_id: $one_line"]
   <h3>Status change \#$msg_id: $one_line</h3>
   [ticket_context [list [list $return_url {Ticket Tracker}] [list {} {Comment for change}]]]<hr>
  Please provide a comment for changing status from <strong>$old_status_long</strong> to <strong>$status_long</strong>.  Note that explaining what was done to fix something will provide a valuable record for others encountering similiar problems.
  <form method=post action=\"[ns_conn url]\">
  <textarea name=status_message rows=12 cols=64 wrap=soft></textarea><br>
   <b>The message above is:</b>
   <input type=radio name=status_msg_html value=\"pre\">Prefomatted text
   <input type=radio name=status_msg_html value=\"plain\" checked>Plain text
   <input type=radio name=status_msg_html value=\"html\">HTML<br>
   <blockquote><input type=submit value=\"Proceed\"></blockquote>
   [export_ns_set_vars form]
   <input type=hidden name=didsubmit value=\"check\">
  </form>"
            ns_write "[ad_general_comments_list $db $msg_id ticket_issues "Ticket \#$msg_id: $one_line" ticket {} {} modified_long 0]\n[ad_footer]"
            return
        } else { 
            switch $status_msg_html {
                "pre" {
                    regsub "\[ \012\015\]+\$" $status_message {} status_message
                    set status_message "<pre>[ns_quotehtml $status_message]</pre>"
                    set status_msg_html t
                } 
                "plain" { 
                    set status_msg_html f
		    
                }
                default { 
                    set status_msg_html t
		
                }
            }

        }
        
        if { $didsubmit == "check" } { 
            ReturnHeaders            
            ns_write "[ad_header "Status change \#$msg_id: $one_line"]
   <h3>Status change \#$msg_id: $one_line</h3>
   [ticket_context [list [list $return_url {Ticket Tracker}] [list {} {Confirm comment for change}]]]<hr>
   Here is how your comment will appear:<p><blockquote><strong>$old_status_long to $status_long</strong><p>"
            if {$status_msg_html == "t" } {
                ns_write $status_message
            } else { 
                ns_write [util_convert_plaintext_to_html $status_message]
            }

            ns_write "<form method=post action=\"[ns_conn url]\">
  <blockquote><input type=submit value=\"Confirm\"></blockquote>
   [export_ns_set_vars form didsubmit]
   <input type=hidden name=didsubmit value=\"yes\">
  </form></blockquote>
 <font size=-1 face=\"verdana, arial, helvetica\">
 Note: if the text above has a bunch of visible HTML tags then you probably
 should have selected \"HTML\" rather than \"Plain Text\".  Use your
 browser's Back button to return to the submission form.  If it is all smashed
 together and you want the original line breaks saved then choose \"Preformatted Text\".
 </font>
 [ad_footer]"
            return
        }
    }



    # build the update statement
    set update_sql "update ticket_issues_i set "
    set form [ns_getform]
    foreach v {project_id domain_id ticket_type_id priority_id severity_id source_id cause_id status_id} { 
        if {[ns_set find $form $v] > -1} {
            append update_sql "$v = [set $v],"
        }
    }

    foreach v {version one_line public_p notify_p from_host from_url from_query from_project} {
        if {[ns_set find $form $v] > -1} {
            util_dbq -null_is_null_p t $v
            append update_sql "$v = [set DBQ$v],"
        }
    }
    
    if {[ns_set find $form deadline] > -1 
        || [ns_set find $form project_deadline] > -1} {
	util_dbq -null_is_null_p t deadline
	append update_sql "deadline = $DBQdeadline,"
    }
   
    append update_sql "last_modified = sysdate, last_modifying_user = $user_id, modified_ip_address = '[DoubleApos [ns_conn peeraddr]]' where msg_id = $msg_id"

    with_transaction $db {
        if {![empty_string_p $status_message] } { 

            set status_comment_id [database_to_tcl_string $db "select general_comment_id_sequence.nextval from dual"]
            ad_general_comment_add $db $status_comment_id {ticket_issues} $msg_id "\#$msg_id $one_line \[to $status_long\]" $status_message $user_id [ns_conn peeraddr] {t} $status_msg_html "$old_status_long to $status_long"
        }
        if { $comment_id && ![empty_string_p $message]} {
	    # check for message type
	    if { $msg_html == "pre" } {
		regsub "\[ \012\015\]+\$" $message {} message
		set message "<pre>[ns_quotehtml $message]</pre>"
		set html_p t
	    } elseif { $msg_html == "html" } { 
		set html_p t
	    } else { 
		set html_p f
	    }
	    
            ad_general_comment_update $db $comment_id $message [ns_conn peeraddr] $html_p $one_line
        }
    
        ns_db dml $db $update_sql
    } { 
        ad_return_complaint 1 "<li>Here was the bad news from the database: <pre>$errmsg</pre>"
        return -code return
    }
}
    
ReturnHeaders

set context  [list [list $return_url {Ticket Tracker}]]
if { $ascopy } { 
    lappend context [list {} {Ticket duplicated}]
    ns_write "[ad_header "Ticket duplicated"]<h3>The ticket #$msg_id: $one_line in $title_long has been duplicated as \#$new_msg_id</h3>"
    set the_msg_id $new_msg_id
    set subject "Ticket copied \#$the_msg_id - $one_line ($title_long) from \#$msg_id" 
    set did copied_ticket
} else { 
    if {![empty_string_p $msg_id]} {
        set the_msg_id $msg_id
        lappend context [list {} {Ticket updated}]
        ns_write "[ad_header "Ticket updated"]<h3>The ticket \"#$the_msg_id: $one_line\" in $title_long has been updated</h3>"
        if {[string compare $old_status_id $status_id] == 0} { 
            set subject "Ticket updated \#$the_msg_id - $one_line (Proj: $title_long)" 
        } else { 
            set subject "Ticket status change \#$the_msg_id - $one_line ($status_long)" 
        }

        set did updated_ticket
    } else {
        lappend context [list {} {Ticket submitted}]
        set the_msg_id $new_msg_id
        ns_write "[ad_header "Ticket submitted"]<h3>Your ticket \"#$the_msg_id: $one_line\" in $title_long has been submitted</h3>"

        set subject "New Ticket \#$the_msg_id - $one_line ($title_long)" 
        set did new_ticket
    }
}

ns_write "[ticket_context $context]<hr>
 You can now:<br>
 <ul>
  <li><a href=\"issue-new.tcl?[export_url_vars return_url project_id mode]\">Add another ticket in $title_long</a>
  <li><a href=\"$return_url\">Return to where you were.</a>
 </ul><br><p>"


set selection [ns_db 0or1row $db "select td.title_long as domain_title, tp.title_long as project_title, priority_long, status_long, one_line as one_line from ticket_issues ti, ticket_domains td, ticket_projects tp where msg_id = $the_msg_id and td.domain_id = ti.domain_id and tp.project_id = ti.project_id"]
if {![empty_string_p $selection]} { 
    set_variables_after_query
}

if { $notify_p == "t" && [string compare $old_status_id $status_id] != 0} {
    if {[empty_string_p $old_status_id] || [string compare $old_status_id $status_id] == 0} {
        set status_msg "STATUS: $status_long"
    } else { 
        set status_msg "STATUS: $status_long (was: $old_status_long)"
    }
    
    if {$status_msg_html == {f}} { 
        set body $status_message
    } else { 
        set body [util_striphtml $status_message]
    } 
    append body "\n\nACTION BY: $username ($email)\nPRIORITY: $priority_long  $status_msg\n\n----------------------------------------\nTicket #$the_msg_id $one_line\n\n"

    if {$msg_html == "plain" } { 
        append body $message
    } else { 
        append body [util_striphtml $message]
    }
    append body "\n\nProject $project_title - $domain_title\n"
    
    ns_write "[ticket_notify $db $did $the_msg_id $subject $body]"
}

ns_write "[ad_footer]"

