# $Id: issue-new.tcl,v 3.14 2000/03/10 22:13:26 davis Exp $
ad_page_variables {
    {msg_id {}}
    {project_id {}} 
    {domain_id {}} 
    {message {}} 
    {mode {}} 
    {from_host {}}
    {from_url {}}
    {from_query {}}
    {from_project {}}
    {one_line {}}
    {deadline {}}
    {ascopy 0} 
    {return_url {/ticket/?}}
}

set db [ns_db gethandle]
set my_user_id [ad_get_user_id]

set my_return_url "return_url=[ns_urlencode [ns_conn url]?[export_ns_set_vars url]]"

set msg_html pre


#
#  This is basically to force people to enter data 
#
set extras(severity_id) {}
set extras(priority_id) {}
set extras(cause_id) {}
set extras(status_id) {}
set extras(source_id) {}
set extras(ticket_type_id) {}


set status_id [database_to_tcl_string $db "select code_id as status_id from ticket_codes_i where code = 'open' and code_type = 'status'"]

if {![empty_string_p $msg_id]} { 
    if { $ascopy } {
        # making a copy -- save some state info
        set copy_msg_id $msg_id
        set new_project_id $project_id
        set is copy
        set mode full
    } else { 
        set is old
    }

    # Load the msg_id data
    if {[regexp {^[ ]*[0-9]+[ ]*$} $msg_id]} {
        set selection [ns_db 0or1row $db "select 
    t.user_id as submitter_user_id, 
    u.email as submitter_email, 
    tp.group_id as project_group_id,
    u.first_names || ' ' || u.last_name as submitter_user_name, 
    to_char(t.posting_time,'Month DD, YYYY HH:MI AM') as pretty_posting_time,
    td.group_id as domain_group_id, g.content as message, g.html_p, 
    tia.user_id as assigned_user_id, t.*
  from ticket_issues t, general_comments g, ticket_domains td, users u, ticket_projects tp, ticket_editable te, ticket_issue_assignments tia
  where t.msg_id = $msg_id 
    and te.msg_id = t.msg_id and te.user_id = $my_user_id
    and g.comment_id(+) = t.comment_id 
    and td.domain_id = t.domain_id 
    and tp.project_id = t.project_id
    and t.user_id = u.user_id
    and tia.user_id(+) = $my_user_id
    and tia.msg_id(+) = t.msg_id"]
        if {[empty_string_p $selection]} {
            set selection [ns_db 0or1row $db "select msg_id from ticket_issues where msg_id = $msg_id"]
            if {[empty_string_p $selection]} {
                ad_return_complaint 1 "<li>Ticket ID \"$msg_id\" does not exist."
                return
            } else { 
                ad_return_complaint 1 "<li>You do not have permission to view Ticket ID \"$msg_id\"."
                return
            }
        }
        set_variables_after_query
    } else {
        ad_return_complaint 1 "<li>Bad ticket ID \"$msg_id\"."
        return
    }
    
    if { $ascopy } { 
        set project_id $new_project_id
    } else { 
        set old_status_long $status_long
        set old_status_id $status_id
    }
    set admin_p [ad_permission_p $db {} {} {} {} $project_group_id]
    set edit_subject_p $admin_p
    if { $my_user_id == $submitter_user_id } { 
        set edit_subject_p 1
    }
    
    if { $html_p == "t" } { 
        if { $edit_subject_p 
             && [regexp {^<pre>([^<]*)</pre>$} $message dummy message]} { 
            set message [util_expand_entities $message]
            set msg_html pre
        } else { 
            set msg_html html
        }
    } else { 
        set msg_html plain
    }

} else { 
    set is new
    set user_id $my_user_id
    # not relevant on booking new ticket.
    set edit_subject_p 1 
    # save User-Agent and creating IP for new tickets.
    set from_user_agent [ns_set get [ns_conn headers] "User-Agent"]
    set from_ip [ns_conn peeraddr]
}


if {[empty_string_p $deadline]} {
    set deadline [database_to_tcl_string $db "select to_char(sysdate+1, 'YYYY-MM-') from dual"]
}

    
if {![empty_string_p $project_id] && [empty_string_p $domain_id]} { 
    set query "from ticket_domains td, ticket_domain_project_map tm
      where (td.end_date is null or td.end_date > sysdate)
        and tm.project_id = $project_id 
        and tm.domain_id = td.domain_id"
    set selection [ns_db 0or1row $db "select count(*) as n_domains $query"]
    if {![empty_string_p $selection]} { 
        set_variables_after_query
    } else {
        ad_return_complaint 1 "<LI> somehow you are trying to move a ticket
         to a project without any feature areas.  We don't like that."
        return
    }
    
    if { $n_domains == 1 } { 
        set domain_id [database_to_tcl_list $db "select td.domain_id $query"]
    }
}
    

    
        

if {([empty_string_p $msg_id] || $ascopy)
    && ([empty_string_p $project_id] || [empty_string_p $domain_id])} {

    # if we dont get a message ID or are copying 
    #   ...ask for a new project unless one is provided 
    ReturnHeaders 
    if { $ascopy } { 
        set msg "Copy Ticket \#$msg_id: \"$one_line\" to"
        ns_write "[ad_header "Copy Ticket \#$msg_id"]
 <h3>Copy Ticket</h3>
 <hr>"
    } else { 
        set msg "New ticket in"
        ns_write "[ad_header "New Ticket"] 
 <h3>New Ticket</h3>

 [ad_context_bar_ws_or_index [list $return_url "Ticket tracker"] "Add ticket"]
 <hr>"
    }
    ns_write "<form method=GET action=\"issue-new.tcl\"><table><tr><th>"
    
    if {[empty_string_p $project_id]} { 
        ns_write "$msg which project?</th>
     <td>[ad_db_select_widget -option_list {{{} {-- Please choose one --}}} $db "select title_long, project_id 
        from ticket_projects tp
        where (end_date is null or end_date > sysdate)
        and exists (select 1 from ticket_domain_project_map tm where tm.project_id = tp.project_id)
        order by UPPER(title_long) asc" project_id]
 <input type=submit value=\"Go\"></td></tr></table>"

        ns_write "[export_ns_set_vars form]</form>
 <p>
 Or you can choose a project in which you have posted in the past:<br><ul>"
    
        set selection [ns_db select $db "select tp.project_id, tp.title_long, count(*) as n from ticket_issues_i ti, ticket_projects tp where tp.project_id = ti.project_id and ti.user_id = $user_id group by tp.project_id, tp.title_long order by n desc"]
        while {[ns_db getrow $db $selection]} { 
            set_variables_after_query
            ns_write "<li> <a href=\"[ns_conn url]?[export_ns_set_vars url project_id]&project_id=$project_id\">$title_long</a> ($n)"
        }
    

        ns_write "</ul><h3>Still not sure where it belongs</h3>
    Here is a list of all the projects with descriptions (follow the link to create a ticket in any given project):<dl>"
        set selection [ns_db select $db "select title_long, project_id, description
    from ticket_projects tp
    where (end_date is null or end_date > sysdate)
       and exists (select 1 from ticket_domain_project_map tm where tm.project_id = tp.project_id)
    order by UPPER(title_long) asc"]
    
        while {[ns_db getrow $db $selection]} { 
            set_variables_after_query
            if {[empty_string_p $description]} { 
                set description {<em>no description provided</em>}
            }
            ns_write "<dt><a href=\"[ns_conn url]?project_id=$project_id&[export_ns_set_vars url project_id]\">$title_long</a><dd>$description"
        }
    } else { 
        ns_write "$msg which feature area?</th>
     <td>[ad_db_select_widget -option_list {{{} {-- Please choose one --}}} $db "select td.title_long, td.domain_id 
        from ticket_domains td, ticket_domain_project_map tm 
        where (td.end_date is null or td.end_date > sysdate)
            and tm.project_id = $project_id
            and tm.domain_id = td.domain_id
        order by UPPER(title_long) asc" domain_id]
 <input type=submit value=\"Go\"></td></tr></table>"

        ns_write "[export_ns_set_vars form]</form>"
    }        
    ns_write "</dl>[ad_footer]"
    return
}



if {! $user_id } {
    # we got no user_id so ask for an email address for contact info
    # TicketUnauthenticatedP t 
    lappend fields email
}


# get some extra info 
if {$is != "old"} { 
    set default_assignee [database_to_tcl_string_or_null $db "select tm.default_assignee from ticket_domain_project_map tm where tm.project_id = $project_id and tm.domain_id = $domain_id"]
    set sql "select ticket_issue_id_sequence.nextval as new_msg_id,"
} else { 
    set default_assignee {}
    set sql "select "
} 
append sql "tp.title_long as project_title_long, tp.code_set, tp.group_id as project_group_id, tp.default_mode, tp.message_template as project_template, td.message_template as domain_template, td.title_long as domain_title_long, td.group_id as domain_group_id
       from ticket_projects tp, ticket_domains td
       where tp.project_id = $project_id and td.domain_id = $domain_id"

set selection [ns_db 0or1row $db $sql]

               
if {[empty_string_p $selection]} { 
    ad_return_complaint 1 "<li>Invalid project or domain id\n"
    return
}
set_variables_after_query

set admin_p [ad_permission_p $db {} {} {} {} $project_group_id]

if {[empty_string_p $mode]} { 
    set mode $default_mode
}

if {$is == "new"} { 
    if {![empty_string_p $domain_template]} { 
        set message $domain_template
    } else { 
        set message $project_template
    }
}
    
switch $mode {
    feedback {
        set fields {domain_id one_line message 
            {msg_html hidden pre} 
            {from_url hidden null}
            {from_host hidden null}
            {from_query hidden null}
            {from_project hidden null}
            {from_user_agent hidden null}
            {from_ip hidden null}
        }
    }
    
    full -    
    default {
        # HP wants this mandatory severity
        set extras(severity_id) {{BaDdAtA {-- Setting Required --}}}
        set fields {domain_id one_line message msg_html} 
       lappend fields ticket_type_id severity_id priority_id deadline status_id cause_id notify_p public_p 
        if {![empty_string_p $from_url] 
            || ![empty_string_p $from_query]
            || ![empty_string_p $from_host]            
            || ![empty_string_p $from_project]} {
            lappend fields from_url from_host from_query from_project from_user_agent from_ip
        }
    }
}

set field_title(domain_id) {Feature area}
set field_title(one_line) {Subject}
set field_title(message) {Message}
set field_title(msg_html) {The above text is}
set field_title(ticket_type_id) {Ticket type}
set field_title(severity_id) {Severity}
set field_title(priority_id) {Priority}
set field_title(status_id) {Status}
set field_title(source_id) {Source}
set field_title(deadline) {Deadline}
set field_title(cause_id) {Defect cause}
set field_title(public_p) {Public to non-project members?}
set field_title(notify_p) {Notify Feature Area Members (via email)?}
set field_title(from_url) {From URL}
set field_title(from_query) {URL Args}
set field_title(from_host) {From Host}
set field_title(from_project) {From Project}
set field_title(from_ip) {From IP}
set field_title(from_user_agent) {User Agent}

set code_type(ticket_type_id) {type}
set code_type(source_id) {source}
set code_type(severity_id) {severity}
set code_type(priority_id) {priority}
set code_type(status_id) {status}
set code_type(cause_id) {cause}

set msg_html_set(pre) {}
set msg_html_set(plain) {}
set msg_html_set(html) {}


ReturnHeaders

switch $is { 
    new { 
        set action "Create Ticket"
        set button "Create"
    }

    copy { 
        set action "Copy Ticket"
        set button "Create Copy"
    }

    default { 
        set action "Edit Ticket"
        set button "Update"
    }
}


if { $mode == "feedback" } {
    # in feedback mode we don;t want people to know it is  
    # a ticket tracker...
    ns_write "[ad_header "[ad_system_name]: $project_title_long"]
 <h3>[ad_system_name]: $project_title_long</h3>
 [ad_context_bar_ws_or_index $project_title_long]
 <hr>
 <blockquote>"
} else {
    regsub -all {(domain_id=|project_id=)[^&]*} $return_url {} return_url
    if {[empty_string_p $msg_id]} { 
        set headline "$action"
    } else { 
        set headline "$action: \#$msg_id $one_line"
    }
    ns_write "[ad_header $headline]
 <h3>$headline</h3>
 [ad_context_bar_ws_or_index \
  [list $return_url "Ticket Tracker"] \
  [list "$return_url&domain_id=all&project_id=$project_id" "$project_title_long"] \
  $action ]
 <hr>
 <blockquote>"
}

set ticket_user_id $user_id
ns_write "<form action=\"issue-new-2.tcl\" method=post>

 [export_form_vars mode return_url project_id new_msg_id msg_id comment_id ascopy ticket_user_id old_status_id old_status_long]
 <table border=0>"
if { $mode != "feedback" } {
    ns_write "<tr><th align=left>Project:</th><td><strong>$project_title_long</strong></td></tr>\n"
}


foreach field $fields {
    # Here we parse the required fields...
    set field_name [lindex $field 0]

    #flag is display or hidden
    if {[llength $field] > 1} {
        set flag [lindex $field 1]
    } else { 
        set flag display
    }

    # defval is field value
    if {[info exists $field_name] 
        && ![empty_string_p [set $field_name]]} {
        set defval [set $field_name]
    } elseif {[llength $field] > 2} {
        set defval [lindex $field 2]
    } else {
        set defval {}
    }
        
    if { $flag == "hidden"} { 
        ns_write "<input type=hidden name=$field_name [export_form_value defval]>\n"
    } else { 
        switch $field_name { 
            domain_id {
                if { 0 } { 
                    ns_write "<tr><th align=left>Feature area:</th><td>[\
                        ad_db_select_widget -default $domain_id \
                        -option_list {{{req} { -- Please choose one --}}} \
                        $db "select title_long, d.domain_id 
                    from ticket_domains d, ticket_domain_project_map m 
                    where m.project_id = $project_id 
                    and m.domain_id = d.domain_id
                    order by title asc" domain_id]</td></tr>"
                } else { 
                    ns_write "<tr><th align=left>Feature area:</th><td><strong>$domain_title_long</strong></td></tr>[export_form_vars domain_id]"
                }

            }

            one_line {
                if { $edit_subject_p } { 
                    ns_write "<tr><th align=left>$field_title($field_name):<td><input type=text name=$field_name size=60 [export_form_value $field_name]></td></tr>"
                } else { 
                    ns_write "<tr><th align=left>$field_title($field_name):<td>$one_line</td></tr>"
                    ns_write "[export_form_vars one_line]"
                }
            }   
            
            message {
                if { $edit_subject_p } { 
                    ns_write "<tr><th align=left>Message</th></tr>
 <tr><td colspan=2><textarea name=message rows=10 cols=64 wrap=soft>$defval</textarea></td></tr>"
                } else { 
                    # export it first
                    ns_write "[export_form_vars message]"
                    # then mess with it
                    if {$msg_html != "html"} {
                        if {$msg_html == "plain"} { 
                            set message [util_convert_plaintext_to_html $message]
                        }
                        regsub -all "(http://\[^ \t\r\n\]+)(\[ \n\r\t\]|$)" $message "<a href=\"\\1\">\\1</a>\\2 " message
                    }

                    ns_write "<tr><td colspan=2><blockquote><table><tr><td bgcolor=f0f0f0>$message<blockquote></td></tr></table></td></tr>"
                    
                }
            }

            msg_html { 
                if { $edit_subject_p } { 

                    set msg_html_set($msg_html) checked
                    ns_write "<tr><td colspan=2 align=left><b>The message above is:</b>
 <input type=radio name=msg_html value=\"pre\" $msg_html_set(pre)>Prefomatted text
 <input type=radio name=msg_html value=\"plain\" $msg_html_set(plain)>Plain text
 <input type=radio name=msg_html value=\"html\" $msg_html_set(html)>HTML</td></tr>"
                } else { 
                    ns_write "[export_form_vars msg_html]"
                }

            }
            # simple text fields 
            from_url -
            from_host -
            from_query -
            from_project -
            from_user_agent - 
            from_ip -
            email {
                ns_write "<tr><th align=left>$field_title($field_name)<td><input type=text name=$field_name size=60 [export_form_value $field_name]></td></tr>"
            }

            # code lookup fields
            severity_id -
            priority_id - 
            cause_id - 
            status_id -
            source_id -
            ticket_type_id { 
                set select [ad_db_select_widget -default $defval -option_list $extras($field_name) $db "select code_long, code_id from ticket_codes where code_set = '[DoubleApos $code_set]' and code_type = '$code_type($field_name)' order by code_seq" $field_name]
                if {![empty_string_p $select] } { 
                    ns_write "<tr>\n<th align=left>$field_title($field_name):</th><td>$select\n</td></tr>\n"
                }
            }
                
            # the y/n flags
            public_p -
            notify_p {
                ns_write "<tr>\n<th colspan=2 align=left>$field_title($field_name) "
                if {$defval != "f"} {
                    ns_write "<input type=radio name=$field_name value=t CHECKED> Yes
  <input type=radio name=$field_name value=f> No</td>\n</th>\n"
                } else {  
                    ns_write "<input type=radio name=$field_name value=t> Yes
  <input type=radio name=$field_name value=f CHECKED> No</th>\n</tr>\n"
                } 
            }
            
            deadline { 
                set select [ad_db_select_widget -blank_if_no_db 1 \
                        -option_list {{0 {--named deadlines--}}} \
                        $db "select 'today - ' || to_char(trunc(sysdate),'Mon FMDDFM'),trunc(sysdate) as deadline from dual 
                UNION
                select 'tomorrow - '||to_char(trunc(sysdate+1),'Mon FMDDFM'), trunc(sysdate+1) as deadline from dual 
                UNION
                select 'next week - '||to_char(trunc(sysdate+7),'Mon FMDDFM'), trunc(sysdate+7) as deadline from dual 
                UNION
                select name || ' - ' || to_char(deadline, 'Mon FMDDFM'), deadline
                from ticket_deadlines 
                where project_id = $project_id
                  and deadline >= trunc(sysdate) 
                order by deadline" project_deadline]
                ns_write "<tr><th align=left>Deadline:</th><td>[ad_dateentrywidget deadline $deadline]"
                if {![empty_string_p $select]} {
                    ns_write "</em> or $select\n</td></tr>\n"
                } else { 
                    ns_write "</td></tr>\n"
                }
            }
        }
    }
}
    if {$is != "new"} {
        ns_write "<tr><td colspan=2>Originally submitted by <a href=\"/shared/community-member.tcl?user_id=$submitter_user_id\">$submitter_user_name</a> on $pretty_posting_time</td></tr>"

    } else { 
        if { $admin_p } {
            set select  [ticket_assignee_select $db $project_id $domain_id $domain_group_id $default_assignee {-- Unassigned --} assignee]
            if { ! [empty_string_p $select]} {  
                ns_write "<tr><th>Assign to:</th><td>$select</td></tr>"
            }
        } else { 
            set assignee $default_assignee
            ns_write "[export_form_vars assignee]"
        }
    }

ns_write "<tr><td align=center colspan=2>
 <input type=submit value=\"$button\">
 </td></tr>
 </table>
 </form>"




# Generate the assigned users list 
if { $is == "old" } { 
    ns_write [ticket_xrefs_display $db $msg_id $return_url]
    #HPMODE -- $admin_p turned off
    ns_write [ticket_assigned_users $db $project_id $domain_id $domain_group_id $msg_id $one_line $my_return_url 1]  
    ns_write "<strong>Actions:</strong><br>[ticket_actions $msg_id $status_class $status_subclass $responsibility $my_user_id $user_id $assigned_user_id $my_return_url edit list]"

}


if {$is == "old" && $mode == "full"} {
    ns_write "<hr>[ad_general_comments_list $db $msg_id ticket_issues "Ticket \#$msg_id: $one_line" ticket {} {} modified_long 0]"
}

ns_write "</blockquote>[ad_footer]"

