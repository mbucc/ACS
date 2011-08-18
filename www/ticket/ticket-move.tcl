# $Id: ticket-move.tcl,v 3.1.2.1 2000/04/28 15:11:35 carsten Exp $
ad_page_variables {
    msg_id
    {project_id {}} 
    {domain_id {}} 
    {return_url {/ticket/}}
}

set db [ns_db gethandle]

if {![regexp {^[ ]*[0-9]+[ ]*$} $msg_id]} {
    ad_return_complaint 1 "<li> Bad ticket ID \"$msg_id\"."
}


# see if we are moving to a project with only one domain and use it if so.
set query "from ticket_domains td, ticket_domain_project_map tm
      where (td.end_date is null or td.end_date > sysdate)
        and tm.project_id = $project_id 
        and tm.domain_id = td.domain_id"

if {![empty_string_p $project_id] && [empty_string_p $domain_id]} { 
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

if {![empty_string_p $project_id] && ![empty_string_p $domain_id]} { 
    ns_db dml $db "update ticket_issues_i 
 set project_id = $project_id, domain_id = $domain_id 
 where msg_id = $msg_id 
   and exists (
     select 1 
     from ticket_domain_project_map 
     where project_id = $project_id 
       and domain_id = $domain_id)" 
    ad_returnredirect $return_url
    return
} 


ReturnHeaders 
ns_write "[ad_header "Move Ticket \#$msg_id"] 
 <h3>Move Ticket \#$msg_id</h3>

 [ad_context_bar_ws_or_index [list $return_url "Ticket tracker"] "Move ticket"]
 <hr>
 <form method=GET action=\"ticket-move.tcl\"><table><tr><th>"

if {[empty_string_p $project_id]} {
    #   ...ask for a new project 
    ns_write "Move the ticket to which project?</th>
     <td>[ad_db_select_widget -option_list {{{} {-- Please choose one --}}} $db "select title_long, project_id 
    from ticket_projects tp
    where (end_date is null or end_date > sysdate)
       and exists (select 1 from ticket_domain_project_map tm where tm.project_id = tp.project_id)
    order by UPPER(title_long) asc" project_id]"
} else { 
    
    #   ...ask for a new domain
    ns_write "Move the ticket to which feature area? </th>
     <td>[ad_db_select_widget -option_list {{{} {-- Please choose one --}}} $db "select td.title_long, td.domain_id 
    from ticket_domains td, ticket_domain_project_map tm
    where (td.end_date is null or td.end_date > sysdate)
    and tm.project_id = $project_id and tm.domain_id = td.domain_id
    order by UPPER(td.title_long) asc" domain_id]"
}

ns_write " <input type=submit value=\"Go\"></td></tr></table>
 [export_ns_set_vars form]</form>[ad_footer]"
return

