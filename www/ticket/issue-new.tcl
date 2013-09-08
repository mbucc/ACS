# /www/ticket/issue-new.tcl
ad_page_contract {
    Page to add a new ticket or edit an existing one
    
    @param msg_id
    @param mapping_key
    @param project_id project to enter the ticket in
    @param domain_id domain to enter the ticket in
    @param message
    @param mode
    @param from_host
    @param from_url
    @param from_query
    @param from_project
    @param one-list
    @param deadline
    @param as_copy are we creating the ticket as a copy of another?
    @param return_url where to go when we are done

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id issue-new.tcl,v 3.21.2.8 2001/01/12 07:29:53 khy Exp
} {
    {msg_id:integer ""}
    {mapping_key {}}
    {project_id:integer ""} 
    {domain_id:integer ""} 
    {message:html {}} 
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

# -----------------------------------------------------------------------------

set my_user_id [ad_verify_and_get_user_id]

set my_return_url "return_url=[ns_urlencode [ns_conn url]?[export_ns_set_vars url]]"

set msg_html plain

#
#  This is basically to force people to enter data 
#
set extras(severity_id) {}
set extras(priority_id) {}
set extras(cause_id) {}
set extras(status_id) {}
set extras(source_id) {}
set extras(ticket_type_id) {}

db_1row open_status_code "
select code_id as status_id from ticket_codes_i 
where code = 'open' and code_type = 'status'"

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
    if {![db_0or1row ticket_info "select 
    t.user_id as submitter_user_id, 
    u.email as submitter_email, 
    tp.group_id as project_group_id,
    u.first_names || ' ' || u.last_name as submitter_user_name, 
    to_char(t.posting_time,'Month DD, YYYY HH:MI AM') as pretty_posting_time,
    td.group_id as domain_group_id, g.content as message, g.html_p, 
    tia.user_id as assigned_user_id, t.*
  from ticket_issues t, general_comments g, ticket_domains td, users u, ticket_projects tp, ticket_editable te, ticket_issue_assignments tia
  where t.msg_id = :msg_id 
    and te.msg_id = t.msg_id and te.user_id = :my_user_id
    and g.comment_id(+) = t.comment_id 
    and td.domain_id = t.domain_id 
    and tp.project_id = t.project_id
    and t.user_id = u.user_id
    and tia.user_id(+) = :my_user_id
    and tia.msg_id(+) = t.msg_id"]} {

	if {![db_0or1row ticket_exists_p "
	select msg_id from ticket_issues where msg_id = :msg_id"] } {

	    ad_return_complaint 1 "<li>Ticket ID \"$msg_id\" does not exist."
	    return
	} else { 
	    ad_return_complaint 1 "<li>You do not have permission to view Ticket ID \"$msg_id\"."
	    return
	}
    }
    
    if { $ascopy } { 
        set project_id $new_project_id
    } else { 
        set old_status_long $status_long
        set old_status_id $status_id
    }
    set admin_p [ad_permission_p {} {} {} {} $project_group_id]
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
    set deadline [db_string default_deadline "select to_char(sysdate+1, 'YYYY-MM-') from dual"]
}

if ![empty_string_p $mapping_key] {
    if { ![empty_string_p $project_id] } {
	ad_return_complaint 1 "<li>You have provided a mapping key. It is not
	necessary to also provide a domain_id."
	return
    }
    set query "select tm.project_id, tm.domain_id from ticket_domains td, ticket_domain_project_map tm \
	    where tm.mapping_key = :mapping_key \
	    and tm.domain_id = td.domain_id"
    if {![db_0or1row get_project_domain_from_mapping_key $query]} {

        ad_return_complaint 1 "<LI>We do not know which project in which to 
	put the tickets for $mapping_key. You can see a list of valid projects
	when you <a href=\"issue-new\">open a new ticket</a>."
        return
    }
    
}
    
if {![empty_string_p $project_id] && [empty_string_p $domain_id]} { 
    set query "from ticket_domains td, ticket_domain_project_map tm
      where (td.end_date is null or td.end_date > sysdate)
        and tm.project_id = :project_id 
        and tm.domain_id = td.domain_id"

    if {! [db_0or1row num_domains "select count(*) as n_domains $query"]} {

        ad_return_complaint 1 "<LI> somehow you are trying to move a ticket
         to a project without any feature areas.  We don't like that."
        return
    }
    
    if { $n_domains == 1 } { 
        db_1row unique_domain "select td.domain_id $query" 
    }
}
    

if {([empty_string_p $msg_id] || $ascopy)
    && ([empty_string_p $project_id] || [empty_string_p $domain_id])} {

    # if we dont get a message ID or are copying 
    #   ...ask for a new project unless one is provided 

    if { $ascopy } { 
        set msg "Copy Ticket \#$msg_id: \"$one_line\" to"
        append page_contents "[ad_header "Copy Ticket \#$msg_id"]
 <h2>Copy Ticket</h2>
 <hr>"
    } else { 
        if {![empty_string_p $project_id]} {
            set page_title "New ticket in [db_string unused "select title_long from ticket_projects where project_id = $project_id"]"
        } else { 
            set page_title "New ticket"
        }
        set msg "New ticket in"
        append page_content "[ad_header $page_title] 
<h2>$page_title</h2>

 [ad_context_bar_ws_or_index [list $return_url "Ticket tracker"] "Add ticket"]
 <hr>"
    }

    append page_content "<form method=GET action=\"issue-new\">
    <table>
     <tr>
      <th>"
    
    if {[empty_string_p $project_id] && [empty_string_p $mapping_key]} { 
        append page_content "$msg which project?</th>
     <td>[ad_db_select_widget -option_list {{{} {-- Please choose one --}}} \
	     project_choices "select title_long, project_id 
        from ticket_projects tp
        where (end_date is null or end_date > sysdate)
        and exists (select 1 from ticket_domain_project_map tm 
                    where tm.project_id = tp.project_id)
        order by UPPER(title_long) asc" project_id]
 <input type=submit value=\"Go\">
	</td>
      </tr>
    </table>

	[export_ns_set_vars form]</form>
 <p>
 Or you can choose a project in which you have posted in the past:<br><ul>"
    
        db_foreach past_projects "
	select tp.project_id, 
	       tp.title_long, 
	       count(*) as n 
	from   ticket_issues_i ti, 
	       ticket_projects tp 
	where  tp.project_id = ti.project_id 
	and    ti.user_id = :user_id 
	group by tp.project_id, tp.title_long 
	order by n desc" {

            append page_content "<li> <a href=\"[ns_conn url]?[export_ns_set_vars url project_id]&project_id=$project_id\">$title_long</a> ($n)"
        }
    
        append page_content "</ul>

	<h3>Still not sure where it belongs</h3>
	Here is a list of all the projects with descriptions (follow the link to create a ticket in any given project):<dl>"
	
	db_foreach all_projects "
	select title_long, 
	       project_id, 
	       description
	from   ticket_projects tp
	where  (end_date is null or end_date > sysdate)
	and    exists (select 1 from ticket_domain_project_map tm 
	               where tm.project_id = tp.project_id)
	order by UPPER(title_long) asc" {
    
            if {[empty_string_p $description]} { 
                set description {<em>no description provided</em>}
            }
            append page_content "
	    <dt><a href=\"[ns_conn url]?project_id=$project_id&[export_ns_set_vars url project_id]\">$title_long</a>
	    <dd>$description"
        }

    } elseif {![empty_string_p $mapping_key]} {
        append page_content "$msg which feature area?</th>
	<td>[ad_db_select_widget -option_list {{{} {-- Please choose one --}}} \
		-bind [ad_tcl_var_to_ns_set mapping_key] \
		domain_choices_from_mapping_key "
	select td.title_long, td.domain_id 
        from ticket_domains td, ticket_domain_project_map tm 
        where (td.end_date is null or td.end_date > sysdate)
	and tm.mapping_key = :mapping_key
	and tm.domain_id = td.domain_id
        order by UPPER(title_long) asc" domain_id]
	<input type=submit value=\"Go\">
	</td>
	</tr>
	</table>

        [export_ns_set_vars form]
	</form>"

    } else { 
        append page_content "$msg which feature area?</th>
     <td>[ad_db_select_widget -option_list {{{} {-- Please choose one --}}} \
	     -bind [ad_tcl_vars_to_ns_set project_id] \
	     domains_for_one_project "
	select td.title_long, td.domain_id 
        from ticket_domains td, ticket_domain_project_map tm 
        where (td.end_date is null or td.end_date > sysdate)
            and tm.project_id = :project_id
            and tm.domain_id = td.domain_id
        order by UPPER(title_long) asc" domain_id]
	<input type=submit value=\"Go\">
	</td>
	</tr>
	</table>

        [export_ns_set_vars form]
	</form>"
    }        
    append page_content "</dl>[ad_footer]"

    doc_return  200 text/html $page_content
    return
}

if {! $user_id } {
    # we got no user_id so ask for an email address for contact info
    # TicketUnauthenticatedP t 
    lappend fields email
}

# get some extra info 
if {$is != "old"} { 
    set default_assignee [db_string \
	    default_assignee_for_project_domain "
    select tm.default_assignee 
    from ticket_domain_project_map tm 
    where tm.project_id = :project_id 
    and tm.domain_id = :domain_id" -default ""]

    set sql "select ticket_issue_id_sequence.nextval as new_msg_id,"
} else { 
    set default_assignee {}
    set sql "select "
} 
append sql "
  tp.title_long as project_title_long, 
  tp.code_set, 
  tp.group_id as project_group_id, 
  tp.default_mode, 
  tp.message_template as project_template, 
  td.message_template as domain_template, 
  td.title_long as domain_title_long, 
  td.group_id as domain_group_id
from ticket_projects tp, ticket_domains td
where tp.project_id = :project_id 
and   td.domain_id = :domain_id"

if { ![db_0or1row project_domain_info $sql] } {

    ad_return_complaint 1 "<li>Invalid project or domain id\n"
    return
}

set admin_p [ad_permission_p {} {} {} {} $project_group_id]

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
    append page_content "
    [ad_header "[ad_system_name]: $project_title_long"]
    <h2>[ad_system_name]: $project_title_long</h2>
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
    append page_content "
    [ad_header $headline]
    <h2>$headline</h2>
    [ad_context_bar_ws_or_index \
	    [list $return_url "Ticket Tracker"] \
	    [list "$return_url&domain_id=all&project_id=$project_id" "$project_title_long"] \
	    $action ]
    <hr>
    <blockquote>"
}

set ticket_user_id $user_id
append page_content "
<form action=\"issue-new-2\" method=POST>

[export_form_vars mode return_url project_id msg_id comment_id ascopy ticket_user_id old_status_id old_status_long]
[export_form_vars -sign new_msg_id]
<table border=0>"

if { $mode != "feedback" } {
    append page_content "
  <tr>
    <th align=left>Project:</th>
    <td><strong>$project_title_long</strong></td>
  </tr>
"
}

# bind vars for select widgets
set bind_vars [ad_tcl_vars_to_ns_set project_id]

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
        append page_content "<input type=hidden name=$field_name [export_form_value defval]>\n"
    } else { 
        switch $field_name { 
            domain_id {
                if { 0 } { 
                    append page_content "
		    <tr><th align=left>Feature area:</th>
		    <td>[ad_db_select_widget -default $domain_id \
                        -option_list {{{req} { -- Please choose one --}}} \
                        -bind $bind_vars domain_choices "
		    select title_long, d.domain_id 
                    from ticket_domains d, ticket_domain_project_map m 
                    where m.project_id = :project_id 
                    and m.domain_id = d.domain_id
                    order by title asc" domain_id]
		    </td>
		    </tr>"
                } else { 
                    append page_content "
		    <tr>
		    <th align=left>Feature area:</th>
		    <td><strong>$domain_title_long</strong></td>
		    </tr>
		    [export_form_vars domain_id]"
                }

            }

            one_line {
                if { $edit_subject_p } { 
                    append page_content "
		    <tr>
		    <th align=left>$field_title($field_name):</th>
		    <td><input type=text name=$field_name size=60 [export_form_value $field_name]></td>
		    </tr>"
                } else { 
                    append page_content "
		    <tr>
		    <th align=left>$field_title($field_name):</th>
		    <td>$one_line</td>
		    </tr>
		    [export_form_vars one_line]"
                }
            }   
            
            message {
                if { $edit_subject_p } { 
                    append page_content "
		    <tr>
		    <th align=left>Message</th>
		    </tr>
		    <tr>
		    <td colspan=2>
		    <textarea name=message rows=10 cols=64 wrap=soft>$defval</textarea>
		    </td>
		    </tr>"
                } else { 
                    # export it first
                    append page_content "[export_form_vars message]"
                    # then mess with it
                    if {$msg_html != "html"} {
                        if {$msg_html == "plain"} { 
                            set message [util_convert_plaintext_to_html $message]
                        }
                        regsub -all "(http://\[^ \t\r\n\]+)(\[ \n\r\t\]|$)" $message "<a href=\"\\1\">\\1</a>\\2 " message
                    }

                    append page_content "
		    <tr>
		    <td colspan=2><blockquote>
		      <table>
		      <tr>
		      <td bgcolor=f0f0f0>$message</td>
		      </tr>
		      </table>
		      </blockquote>
		    </td>
		    </tr>"
                    
                }
            }

            msg_html { 
                if { $edit_subject_p } { 

                    set msg_html_set($msg_html) checked
                    append page_content "
		    <tr>
		    <td colspan=2 align=left>
		    <b>The message above is:</b>
<input type=radio name=msg_html value=\"pre\" $msg_html_set(pre)>Preformatted text
<input type=radio name=msg_html value=\"plain\" $msg_html_set(plain)>Plain text
<input type=radio name=msg_html value=\"html\" $msg_html_set(html)>HTML</td></tr>"
                } else { 
                    append page_content "[export_form_vars msg_html]"
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
                append page_content "
		<tr>
		<th align=left>$field_title($field_name)</th>
		<td><input type=text name=$field_name size=60 [export_form_value $field_name]></td>
		</tr>"
            }

            # code lookup fields
            severity_id -
            priority_id - 
            cause_id - 
            status_id -
            source_id -
            ticket_type_id { 
		
		set code_bind_vars [ns_set create]
		ns_set put $code_bind_vars code_set $code_set
		ns_set put $code_bind_vars type $code_type($field_name)

                set select [ad_db_select_widget -default $defval \
			-option_list $extras($field_name) \
			-bind $code_bind_vars code_choices "
		select code_long, code_id 
		from ticket_codes 
		where code_set = :code_set 
		and code_type = :type 
		order by code_seq" $field_name]
		ns_set free $code_bind_vars

		# Used to check for ![empty_string_p $select]
		# but this is wrong because ad_db_select_widget
		# always returns <select>...</select>
		# So, instead we look for the string 'option'
		# Note that wouldn't matter except that IE 4.5/5
		# for the Mac has a bug when it encounters an
		# empty select
                if { [regexp "option" $select]} { 
                    append page_content "
		    <tr>
		    <th align=left>$field_title($field_name):</th>
		    <td>$select</td>
		    </tr>"
                }
            }
                
            # the y/n flags
            public_p -
            notify_p {
                append page_content "
		<tr>
		<th colspan=2 align=left>$field_title($field_name) "
                if {$defval != "f"} {
                    append page_content "<input type=radio name=$field_name value=t CHECKED> Yes
  <input type=radio name=$field_name value=f> No</td>\n</th>\n"
                } else {  
                    append page_content "<input type=radio name=$field_name value=t> Yes
  <input type=radio name=$field_name value=f CHECKED> No</th>\n</tr>\n"
                } 
            }
            
            deadline { 
                set select [ad_db_select_widget -blank_if_no_db 1 \
                        -option_list {{0 {--named deadlines--}}} \
			-bind $bind_vars \
			deadline_select "
		select 'today - ' || to_char(trunc(sysdate),'Mon FMDDFM'),trunc(sysdate) as deadline from dual 
                UNION
                select 'tomorrow - '||to_char(trunc(sysdate+1),'Mon FMDDFM'), trunc(sysdate+1) as deadline from dual 
                UNION
                select 'next week - '||to_char(trunc(sysdate+7),'Mon FMDDFM'), trunc(sysdate+7) as deadline from dual 
                UNION
                select 'next month - '||to_char(trunc(ADD_MONTHS(sysdate,1)),'Mon FMDDFM'), trunc(ADD_MONTHS(sysdate,1)) as deadline from dual
                UNION
                select name || ' - ' || to_char(deadline, 'Mon FMDDFM'), deadline
                from ticket_deadlines 
                where project_id = :project_id
                  and deadline >= trunc(sysdate) 
                order by deadline" project_deadline]

                append page_content "
		<tr>
		<th align=left>Deadline:</th>
		<td>[ad_dateentrywidget deadline $deadline]"
                if {![empty_string_p $select]} {
                    append page_content "</em> or $select\n</td></tr>\n"
                } else { 
                    append page_content "</td></tr>\n"
                }
            }
        }
    }
}

if {$is != "new"} {
    append page_content "
    <tr>
    <td colspan=2>Originally submitted by <a href=\"/shared/community-member?user_id=$submitter_user_id\">$submitter_user_name</a> on $pretty_posting_time</td>
    </tr>"

} else { 
    if { $admin_p } {
	set select  [ticket_assignee_select $domain_group_id $default_assignee {-- Unassigned --} assignee]
	if { ! [empty_string_p $select]} {  
	    append page_content "
	    <tr>
	    <th>Assign to:</th>
	    <td>$select</td>
	    </tr>"
	}
    } else { 
	set assignee $default_assignee
	append page_content "[export_form_vars assignee]"
    }
}

append page_content "
<tr>
 <td align=center colspan=2>
 <input type=submit value=\"$button\">
 </td>
</tr>
</table>
</form>"

# Generate the assigned users list 
if { $is == "old" } { 
    #HPMODE -- $admin_p turned off
    append page_content "
    [ticket_xrefs_display $msg_id $return_url]
    [ticket_assigned_users $project_id $domain_id $domain_group_id $msg_id $one_line $my_return_url 1]  
    <strong>Actions:</strong><br>[ticket_actions $msg_id $status_class $status_subclass $responsibility $my_user_id $user_id $assigned_user_id $my_return_url edit list]"

}

if {$is == "old" && $mode == "full"} {
    append page_content "
    <hr>
    [ad_general_comments_list $msg_id ticket_issues "Ticket \#$msg_id: $one_line" ticket {} {} modified_long 0]"
}

append page_content "</blockquote>[ad_footer]"

doc_return 200 text/html $page_content

