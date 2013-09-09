# /www/ticket/issue-new-2.tcl

ad_page_contract {
    Process information for new ticket.

    @param project_id new project for the ticket
    @param domain_id new domain for the ticket
    @param one_line short description of the problem
    @param message full description of the problem
    @param msg_html is the message in html?
    @param new_msg_id the new message ID if this is a new or copied ticket
    @param msg_id the old message ID if this is an edit or a copy
    @param comment_id the comment associated with this change/addition
    @param public_p publically viewable?
    @param notify_p notify the submitter of changes?
    @param ticket_type_id  
    @param severity_id  
    @param priority_id  
    @param cause_id  
    @param source_id  
    @param status_id 
    @param deadline a custom deadline entered by the user
    @param project_deadline one of the preset deadlines
    @param from_url  
    @param from_query  
    @param from_project 
    @param from_host  
    @param from_ip  
    @param from_user_agent 
    @param assignee user assigned to address the issue
    @param return_url where to go when we are done
    @param ticket_user_id if this is a copy, the original user
    @param ascopy was this created a a copy of an existing ticket?
    @param old_status_long 
    @param old_status_id 
    @param status_message a message for the change of status
    @param status_msg_html is the status message html? 
    @param didsubmit checks if the status message looks okay (check/yes)
    @param mode 

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id issue-new-2.tcl,v 3.13.2.13 2001/01/12 07:54:04 khy Exp
} {
    project_id:integer 
    domain_id:integer
    one_line:trim,notnull
    message:html
    msg_html 
    {new_msg_id:integer,verify ""} 
    {msg_id:integer ""} 
    {comment_id:integer 0}
    {public_p t}
    {notify_p t} 
    {ticket_type_id:integer ""} 
    {severity_id:integer ""} 
    {priority_id:integer ""} 
    {cause_id:integer ""} 
    {source_id:integer ""} 
    {status_id:integer ""}
    {from_url ""} 
    {from_query ""} 
    {from_project ""}
    {from_host ""} 
    {from_ip null} 
    {from_user_agent null}
    {assignee ""}
    {return_url "/ticket/"}
    {ticket_user_id ""}
    {ascopy 0} 
    {old_status_long ""}
    {old_status_id ""}
    {status_message:html ""}
    {status_msg_html ""}
    {didsubmit ""}
    {mode ""}
    {deadline:array,optional}
    {project_deadline ""} 
} -validate {
    valid_deadline {
	if {[info exists deadline(day)] && ![empty_string_p $deadline(day)]} {
	    ad_page_contract_filter_proc_date deadline deadline
	}
    }
}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

if {[empty_string_p $ticket_user_id]} {
    set ticket_user_id $user_id
}

if {[empty_string_p $old_status_long]} {
    set old_status_long undefined
}

page_validation {

    if {!$ascopy && ![empty_string_p $msg_id] && \
	    ![empty_string_p $new_msg_id]} {
	error "Internal: cannot have msg_id and new_msg_id"
    } elseif {[empty_string_p $msg_id] && [empty_string_p $new_msg_id]} { 
	error "Internal: Must have msg_id or new_msg_id set"
    }
}

if { [empty_string_p $message] } {
    set message $one_line
}

db_1row user_info "
select to_char(sysdate,'Month, DD YYYY ') || sysdate as when_saved, 
       email, 
       first_names || ' ' || last_name as username 
from   users 
where  user_id = :user_id"

page_validation {
    if { ![db_0or1row project_info "
    select title_long, 
           version 
    from   ticket_projects 
    where  project_id = :project_id"]} {
        error "I was unable to look up your project id.<pre>$msg</pre>"
    }
}


# -----------------------------------------------------------------------------

# NEED TO FIGURE OUT HOW TO HANDLE WHEN BOTH SET (I think need to track named deadlines seperately).

if { [exists_and_not_null deadline(day)] } {
    set ora_deadline $deadline(date)
} elseif {![empty_string_p $project_deadline] && $project_deadline != "0"} { 
    set ora_deadline $project_deadline
} else {
    set ora_deadline [db_null]
}

if {![empty_string_p $new_msg_id]} { 
    db_0or1row dbl_click_check "
    select priority_long, status_long, one_line as old_one_line 
    from ticket_issues where msg_id = :new_msg_id"
}

if { $ascopy || ![empty_string_p $new_msg_id] } {
    if {[info exists old_one_line]} {
	
        doc_return  200 text/html "
	[ad_header "Duplicate ID in database"]
	<H2>Ticket \"\#$new_msg_id - $old_one_line\" already 
	exists in the database.</H2>

        [ticket_context [list [list $return_url {Ticket Tracker}] \
		[list {} {Duplicate ID found}]]]<hr>
	<ul> 
	<LI>If you are sure this is a new ticket you can 
	<a href=\"[ns_conn url]?[export_ns_set_vars url new_msg_id]&new_msg_id=[db_string next_msg_id "select ticket_issue_id_sequence.nextval from dual"]\">resubmit it</a>.
	<li>If you double clicked you can <a href=\"$return_url\">return to the main screen</a>.
        </ul>
	[ad_footer]"
        return

    }

    if {! $ascopy } {
        # set directly from submitter.
        set from_user_agent [ns_set get [ns_conn headers] {User-Agent}]
        set from_ip [ns_conn peeraddr]
    } 
        

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

	ad_general_comment_add $comment_id {ticket_issues_i} $new_msg_id "\#$new_msg_id $one_line" $message $ticket_user_id [ns_conn peeraddr] {t} $html_p $one_line


        # create the ticket
        db_dml ticket_insert "insert into ticket_issues_i
	(msg_id, project_id, version, domain_id, user_id, one_line,
	 comment_id, ticket_type_id, priority_id, severity_id, source_id, 
	 cause_id, status_id, posting_time, deadline, public_p, notify_p, 
	 from_host, from_url, from_query, from_project, from_ip, 
	 from_user_agent, last_modified, last_modifying_user, 
	 modified_ip_address)
	values 
	(:new_msg_id,:project_id,:version,:domain_id, :ticket_user_id,
	 :one_line, :comment_id, :ticket_type_id, :priority_id, :severity_id, 
	 :source_id, :cause_id, :status_id, sysdate, :ora_deadline, :public_p, 
	 :notify_p, :from_host, :from_url, :from_query, :from_project, 
	 :from_ip, :from_user_agent, sysdate, :user_id, 
	 '[DoubleApos [ns_conn peeraddr]]')"

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
	(:new_msg_id, empty_clob(), sysdate) 
	returning indexed_stuff into :1" -clobs [list $indexed_stuff]
        if { $ascopy } {
            db_dml xref_insert "
	    insert into ticket_xrefs values (:msg_id, :new_msg_id)"
	}
    } on_error {
        # something went a bit wrong during the insert
        ad_return_complaint 1 "<li>Here was the bad news from the database:
 <pre>$errmsg</pre>"
        return -code return
    }

} else { 

    # msg_id so do update instead

    # first see if we need a comment for this change 
    if { [string compare $status_id $old_status_id] != 0} { 
        set status_long [db_string new_status_name "
	select code_long from ticket_codes_i where code_id = :status_id"]
        
        if { [empty_string_p $status_message] } {
	    db_release_unused_handles
	    doc_return 200 text/html "
[ad_header "Status change \#$msg_id: $one_line"]
<h2>Status change \#$msg_id: $one_line</h2>

[ticket_context [list [list $return_url {Ticket Tracker}] \
	[list {} {Comment for change}]]]<hr>
  
Please provide a comment for changing status from
<strong>$old_status_long</strong> to <strong>$status_long</strong>.
Note that explaining what was done to fix something will provide a
valuable record for others encountering similiar problems.

  <form method=post action=\"[ns_conn url]\">
  <textarea name=status_message rows=12 cols=64 wrap=soft></textarea><br>
   <b>The message above is:</b>
   <input type=radio name=status_msg_html value=\"pre\">Preformatted text
   <input type=radio name=status_msg_html value=\"plain\" checked>Plain text
   <input type=radio name=status_msg_html value=\"html\">HTML<br>
   <blockquote><input type=submit value=\"Proceed\"></blockquote>
   [export_ns_set_vars form]
   <input type=hidden name=didsubmit value=\"check\">
  </form>

[ad_general_comments_list $msg_id ticket_issues "Ticket \#$msg_id: $one_line" ticket {} {} modified_long 0]

[ad_footer]"

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
            append page_content "
	    [ad_header "Status change \#$msg_id: $one_line"]
	    <h2>Status change \#$msg_id: $one_line</h2>
   [ticket_context [list [list $return_url {Ticket Tracker}] \
	   [list {} {Confirm comment for change}]]]<hr>
   Here is how your comment will appear:<p>
<blockquote><strong>$old_status_long to $status_long</strong><p>"

            if {$status_msg_html == "t" } {
                append page_content $status_message
            } else { 
                append page_content [util_convert_plaintext_to_html $status_message]
            }

            append page_content  "
<form method=post action=\"[ns_conn url]\">
  <blockquote><input type=submit value=\"Confirm\"></blockquote>
   [export_ns_set_vars form didsubmit]
   <input type=hidden name=didsubmit value=\"yes\">
</form>
</blockquote>

 <font size=-1 face=\"verdana, arial, helvetica\">
 Note: if the text above has a bunch of visible HTML tags then you probably
 should have selected \"HTML\" rather than \"Plain Text\".  Use your
 browser's Back button to return to the submission form.  If it is all smashed
 together and you want the original line breaks saved then choose \"Preformatted Text\".
 </font>
 [ad_footer]"

            db_release_unused_handles
            doc_return 200 text/html $page_content
            return
        }
    }

    # build the update statement
    set update_sql "update ticket_issues_i set "

    foreach v {project_id domain_id ticket_type_id priority_id severity_id source_id cause_id status_id version one_line public_p notify_p from_host from_url from_query from_project} { 
	append update_sql "$v = :$v,"
    }
    
    append update_sql "deadline = :ora_deadline,"
    append update_sql "last_modified = sysdate, last_modifying_user = :user_id, modified_ip_address = '[DoubleApos [ns_conn peeraddr]]' where msg_id = :msg_id"

    db_transaction {
        if {![empty_string_p $status_message] } { 

            set status_comment_id [db_string next_comment_id "
	    select general_comment_id_sequence.nextval from dual"]

            ad_general_comment_add $status_comment_id {ticket_issues} $msg_id "\#$msg_id $one_line \[to $status_long\]" $status_message $user_id [ns_conn peeraddr] {t} $status_msg_html "$old_status_long to $status_long"

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
	    
            ad_general_comment_update $comment_id $message [ns_conn peeraddr] $html_p $one_line
        }
    
        db_dml ticket_update $update_sql
    } on_error { 
        ad_return_complaint 1 "<li>Here was the bad news from the database: <pre>$errmsg</pre>"
        return -code return
    }
}
    
set context  [list [list $return_url {Ticket Tracker}]]

if { $ascopy } { 
    lappend context [list {} {Ticket duplicated}]

    append page_content "
    [ad_header "Ticket duplicated"]

    <h2>The ticket #$msg_id: $one_line in $title_long has been duplicated as \#$new_msg_id</h2>"

    set the_msg_id $new_msg_id
    set subject "Ticket copied \#$the_msg_id - $one_line ($title_long) from \#$msg_id" 
    set did copied_ticket

} else { 

    if {![empty_string_p $msg_id]} {
        set the_msg_id $msg_id
        lappend context [list {} {Ticket updated}]
        append page_content "
	[ad_header "Ticket updated"]

	<h2>The ticket \"#$the_msg_id: $one_line\" in $title_long has been updated</h2>"

        if {[string compare $old_status_id $status_id] == 0} { 
            set subject "Ticket updated \#$the_msg_id - $one_line (Proj: $title_long)" 
        } else { 
            set subject "Ticket status change \#$the_msg_id - $one_line ($status_long)" 
        }

        set did updated_ticket
    } else {
        lappend context [list {} {Ticket submitted}]
        set the_msg_id $new_msg_id
        append page_content "
	[ad_header "Ticket submitted"]
	<h2>Your ticket \"#$the_msg_id: $one_line\" in $title_long has been submitted</h2>"

        set subject "New Ticket \#$the_msg_id - $one_line ($title_long)" 
        set did new_ticket
    }
}

append page_content "
[ticket_context $context]

<hr>
 You can now:<br>
 <ul>
  <li><a href=\"issue-new?[export_url_vars return_url project_id mode]\">Add another ticket in $title_long</a>
  <li><a href=\"$return_url\">Return to where you were.</a>
 </ul>
<br>
<p>"

db_0or1row domain_project_info "
select td.title_long as domain_title, 
       tp.title_long as project_title, 
       priority_long, 
       status_long, 
       one_line as one_line 
from   ticket_issues ti, 
       ticket_domains td, 
       ticket_projects tp 
where  msg_id = :the_msg_id 
and    td.domain_id = ti.domain_id 
and    tp.project_id = ti.project_id"

if { $notify_p == "t" && [string compare $old_status_id $status_id] != 0} {
    if {[empty_string_p $old_status_id] || [string compare $old_status_id $status_id] == 0} {
        set status_msg "STATUS: $status_long"
    } else { 
        set status_msg "STATUS: $status_long (was: $old_status_long)"
    }
    
    if {$status_msg_html == {f}} { 
        set body [wrap_string $status_message 80]
    } else { 
        set body [util_striphtml $status_message]
    } 
    append body "

ACTION BY: $username ($email)
PRIORITY: $priority_long  $status_msg

----------------------------------------
Ticket #$the_msg_id $one_line

"

    if {$msg_html == "plain" } { 
        append body [wrap_string $message 80]
    } else { 
        append body [util_striphtml $message]
    }
    append body "\n\nProject $project_title - $domain_title\n"
    
    append page_content "[ticket_notify $did $the_msg_id $subject $body]"
}

append page_content "[ad_footer]"

db_release_unused_handles
doc_return 200 text/html $page_content
