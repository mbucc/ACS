# /www/ticket/ticket-move.tcl
ad_page_contract {
    Move a ticket to a new project/domain

    @param msg_id the ID of the ticket to move
    @param project_id the ID of the new project
    @param domain_id the ID of the new domain
    @param return_url where to do when we are done

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id ticket-move.tcl,v 3.5.2.7 2000/09/22 01:39:24 kevin Exp
} {
    msg_id:integer,notnull
    {project_id:integer ""} 
    {domain_id:integer ""} 
    {return_url "/ticket/"}
}

# -----------------------------------------------------------------------------

page_validation {
    if {![db_0or1row get_old_project_domain_info "
    select one_line, 
           project_id as old_project_id, 
           domain_id as old_domain_id 
    from  ticket_issues 
    where msg_id = :msg_id"]} {

	error "Bad ticket ID \"$msg_id\"."
    }
}

# see if we are moving to a project with only one domain and use it if so.
set query "from ticket_domains td, ticket_domain_project_map tm
      where (td.end_date is null or td.end_date > sysdate)
        and tm.project_id = :project_id 
        and tm.domain_id = td.domain_id"

# I don't think this actually does what someone thought it does - KS
if {![empty_string_p $project_id] && [empty_string_p $domain_id]} { 
    if {![db_0or1row get_number_of_domains "
    select count(*) as n_domains $query"] } {

        ad_return_complaint 1 "<LI> somehow you are trying to move a ticket
         to a project without any feature areas.  We don't like that."
        return
    }
    
    if { $n_domains == 1 } { 
        db_1row get_unique_domain_id "select td.domain_id $query"
    }
}

if {![empty_string_p $project_id] && ![empty_string_p $domain_id]} { 
    db_dml project_domain_set "
    update ticket_issues_i 
    set    project_id = :project_id, 
           domain_id = :domain_id 
    where  msg_id = :msg_id 
    and    exists (select 1 from ticket_domain_project_map 
                   where project_id = :project_id 
                   and domain_id = :domain_id)" 
    ad_returnredirect $return_url
    return
} 

set page_content "
[ad_header "Move Ticket \#$msg_id - $one_line"] 
<h2>Move Ticket \#$msg_id - $one_line</h2>

[ad_context_bar_ws_or_index [list $return_url "Ticket tracker"] "Move ticket"]

<hr>

<form method=GET action=\"ticket-move\">

<table>
 <tr>
  <th>"

if {[empty_string_p $project_id]} {
    #   ...ask for a new project 
    append page_content "Move the ticket to which project?</th>
     <td>[ad_db_select_widget -default $old_project_id -option_list {{{} {-- Please choose one --}}} projects "select title_long, project_id 
    from ticket_projects tp
    where (end_date is null or end_date > sysdate)
       and exists (select 1 from ticket_domain_project_map tm where tm.project_id = tp.project_id)
    order by UPPER(title_long) asc" project_id]"
} else { 
    
    #   ...ask for a new domain
    append page_content "Move the ticket to which feature area? </th>
     <td>[ad_db_select_widget -default $old_domain_id \
	     -option_list {{{} {-- Please choose one --}}} \
	     -bind [ad_tcl_vars_to_ns_set project_id] features "
    select td.title_long, td.domain_id 
    from ticket_domains td, ticket_domain_project_map tm
    where (td.end_date is null or td.end_date > sysdate)
    and tm.project_id = :project_id and tm.domain_id = td.domain_id
    order by UPPER(td.title_long) asc" domain_id]"
}

append page_content " <input type=submit value=\"Go\"></td>
 </tr>
</table>

[export_ns_set_vars form]
</form>
[ad_footer]"

doc_return  200 text/html $page_content


















