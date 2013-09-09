# /www/ticket/issue-view.tcl
ad_page_contract { 
    View the details of one ticket

    @param msg_id the ID of the ticket
    @param mode what mode we are in.  One of <code>full</code>, 
           <code>feedback</code>
    @param return_url where to go when we finish

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id issue-view.tcl,v 3.17.2.7 2000/09/22 01:39:24 kevin Exp
} {
    msg_id:integer,notnull
    {mode "full"}
    {return_url "/ticket/?"}
}

# -----------------------------------------------------------------------------

set scope public

set my_return_url "return_url=[ns_urlencode [ns_conn url]?[export_ns_set_vars url]]"


set my_user_id [ad_verify_and_get_user_id]

set query "select 
   ti.*, 
   users.email,
   users.user_id as ticket_user_id,
   users.first_names || '&nbsp;' || users.last_name as user_name,
   tp.project_id,
   tp.title as project_title,
   tp.title_long as project_title_long,
   tp.version,
   td.title as domain_title,
   td.title_long as domain_title_long,
   td.group_id as domain_group_id,
   gc.content as message, 
   gc.html_p as message_html_p, 
   mu.email as modifier_email, 
   mu.user_id as modifier_user_id, 
   mu.first_names || '&nbsp;' || mu.last_name as modifier_user_name,
   cu.email as close_email, 
   cu.user_id as close_user_id, 
   cu.first_names || '&nbsp;' || cu.last_name as close_user_name,
   to_char(ti.posting_time, 'MM/DD/YY') as posting_time_mdy, 
   to_char(ti.posting_time, 'Month DD, YYYY HH:MI AM') as posting_time_long,
   to_char(ti.last_modified, 'MM/DD/YY') as last_modified_mdy, 
   to_char(ti.last_modified, 'Month DD, YYYY HH:MI AM') as last_modified_long,
   to_char(ti.closed_date, 'Month DD, YYYY HH:MI AM') as closed_date_long,
   tia.user_id as assigned_user_id
 from ticket_issues ti, 
   ticket_viewable tv, 
   ticket_projects tp, 
   ticket_domains td, 
   users, 
   users mu,
   users cu,
   general_comments gc, 
   ticket_issue_assignments tia
 where users.user_id = ti.user_id
   and tv.msg_id = ti.msg_id and tv.user_id = :my_user_id
   and tp.project_id = ti.project_id 
   and td.domain_id = ti.domain_id 
   and mu.user_id(+) = ti.last_modifying_user
   and gc.comment_id(+) = ti.comment_id
   and cu.user_id(+) = ti.closed_by 
   and ti.msg_id = :msg_id
   and tia.user_id(+) = :my_user_id
   and tia.msg_id(+) = ti.msg_id"

page_validation {
    if {![db_0or1row get_allowed_ticket_info $query]} {
	if {![db_0or1row check_ticket_existence "
	select msg_id from ticket_issues where msg_id = :msg_id"]} {
            error "Ticket ID \"$msg_id\" does not exist."
        } else { 
            error "You do not have permission to view Ticket ID \"$msg_id\"."
        }
    }
}

regsub -all {(domain_id=|project_id=)[^&]*} $return_url {} return_url

if { $mode == "feedback" } {
    # in feedback mode we don;t want people to know it is  
    # a ticket tracker...
    append page "
    [ad_header "[ad_system_name] $project_title_long"]
    <h2>[ad_system_name] $project_title_long - $one_line</h2>
    [ad_context_bar_ws_or_index $project_title_long]
    <hr>\n"
} else {
    append page "
    [ad_header "TR\#$msg_id - $one_line"]
    <h2>Ticket \#$msg_id - $one_line ($project_title_long)</h2>
    [ad_context_bar_ws_or_index \
	    [list $return_url "Ticket Tracker"] \
	    [list "$return_url&domain_id=all&project_id=$project_id" "$project_title_long"] \
	    [list "$return_url&domain_id=$domain_id&project_id=$project_id" "$domain_title_long"] \
	    "View ticket"]
    <hr>\n"

}

if {$message_html_p == "f"
    || [regexp {^<pre>([^<]*)</pre>$} $message] } {

    if {$message_html_p == "f"} { 
        set message [util_convert_plaintext_to_html $message]
    }

    regsub -all "(http://\[^ \t\r\n\]+)(\[ \n\r\t\]*)" $message "<a href=\"\\1\">\\1</a>\\2" message
    
}

append page "
\[ [ticket_actions $msg_id $status_class $status_subclass $responsibility \
	$my_user_id $ticket_user_id $assigned_user_id \
	"project_id=$project_id&domain_id=$domain_id&return_url=[ns_urlencode $return_url]" view line] \]<br>

<blockquote>

 <strong>$project_title_long - $domain_title_long</strong>
 <br><br><strong>Subject: $one_line</strong><p>
 <table border=0 width=\"90%\">
  <tr>
   <td bgcolor=\"\#f0f0f0\">$message</td>
  </tr>
 </table>"

set field(ticket_type_long) {{Type} {}}
set field(severity_long) {{Severity} {}}
set field(priority_long) {{Priority} {}}
set field(status_long) {{Status} {}}
set field(defect_long) {{Defect} {}}
set field(deadline_mdy) {{Deadline} {}}
set field(public_p) {{} {Public to non-project members? [util_PrettyBoolean $public_p]}}
set field(notify_p) {{} {Notify feature area members via email? [util_PrettyBoolean $notify_p]}}
set field(from_url) {{From URL} {<a href="$from_host$from_url?$from_query">$from_host$from_url</a>}}
set field(from_project) {{From Project} {}}
set field(project_title_long) {{Project} {}}
set field(domain_title_long) {{Feature Area} {}}
set field(email) {{Original submitter} { [ticket_user_display $user_name $email $ticket_user_id] on $posting_time_long}}
set field(modifier_email) {{Modified by} {[ticket_user_display $modifier_user_name $modifier_email $modifier_user_id] on $last_modified_long}}
set field(close_email) {{Closed by} {[ticket_user_display $close_user_name $close_email $close_user_id] on $closed_date_long}}
set field(from_url) {{From URL} {<a href="$from_host$from_url">$from_host$from_url</a> (<a href="$from_host$from_url?$from_query">with vars</a>)}}
set field(from_project) {{From Project} {}}
set field(from_user_agent) {{Submitter's<br>user agent} {}}

append page "<table>\n"

set show {ticket_type_long status_long severity_long priority_long deadline_mdy notify_p public_p email}

if {[string compare $last_modified_long $posting_time_long] != 0
    && [string compare $closed_date_long $last_modified_long] != 0} { 
    lappend show  modifier_email
}
if {![empty_string_p $close_email]} { 
    lappend show close_email
}
lappend show  from_url from_project from_user_agent

foreach fname $show {
    if {![empty_string_p [set $fname]]} {
        if {![empty_string_p [lindex $field($fname) 1]]} {
            set val [subst [lindex $field($fname) 1]]
        } else { 
            set val [set $fname]
        }
        if {![empty_string_p [lindex $field($fname) 0]]} {
            append page "<tr><td>[lindex $field($fname) 0]</td><th align=left>$val</th></tr>\n"
        } else { 
            append page "<tr><td colspan=2>$val</td></tr>"
        }
    }
}

append page "</table>

[ticket_xrefs_display $msg_id $return_url]

<p><strong>Actions:</strong>
[ticket_actions $msg_id $status_class $status_subclass $responsibility \
	$my_user_id $ticket_user_id $assigned_user_id \
	"return_url=[ns_urlencode $return_url]" view list]"

# Generate the assigned users list 
#set admin_p [ad_permission_p $db {} {} {} {} $domain_group_id]
#HPMODE
set admin_p 1 

if { $admin_p } { 
    append page [ticket_assigned_users $project_id $domain_id $domain_group_id $msg_id $one_line $my_return_url $admin_p]  
}

append page "<hr>[ad_general_comments_list $msg_id ticket_issues "Ticket \#$msg_id: $one_line" ticket {} {} modified_long 0]

</blockquote>
 [ad_footer]"

doc_return  200 text/html $page

