# $Id: domain-remove.tcl,v 3.0.4.1 2000/04/28 15:11:37 carsten Exp $
ad_page_variables {domain_id project_id {force 0} {return_url {/ticket/admin/}}}

set db [ns_db gethandle]
set user_id [ad_get_user_id]

set bad 0
set msg {} 
if {![regexp {^[ ]*[0-9]+[ ]*$} $domain_id]} {
    incr bad 
    append  msg "<LI>Bad domain ID \"$domain_id\"."
}
if {![regexp {^[ ]*[0-9]+[ ]*$} $project_id]} {
    incr bad 
    append  msg "<LI>Bad project ID \"$project_id\"."
}

if { $bad } { 
    ad_return_complaint $bad $msg
    return
}

set selection [ns_db 0or1row $db "select td.title_long as domain_title, tp.title_long as project_title, tic.n_tickets
 from ticket_domains td, ticket_projects tp, 
   (select domain_id, project_id, count(*) as n_tickets 
    from ticket_issues_i group by domain_id, project_id) tic
 where td.domain_id = $domain_id
  and tp.project_id = $project_id
  and tic.domain_id(+) = $domain_id
  and tic.project_id(+) = $project_id"]


if {[empty_string_p $selection] || $force} { 
    # got no rows so nuke away buddy
    ns_db dml $db "delete ticket_domain_project_map where domain_id = $domain_id and project_id = $project_id"
    ad_returnredirect "$return_url&action_msg=[ns_urlencode {Domain Project mapping deleted}]"
} else {
    set_variables_after_query
    set force 1
    ns_return 200 text/html "[ad_header "Remove Project-Feature Area Mapping"]\n<h1>Confirm removal of Project-Feature Area Mapping</h1><hr>\n
    <blockquote>$n_tickets tickets exist for domain \"$domain_title\" in project \"$project_title\".<br>
 Remove the association anyway?<blockquote>
 <form><input type=submit value=\"Yes\">[export_form_vars force return_url domain_id project_id return_url]</form>
 </blockquote>
 <em>This action will not remove the tickets or the feature area.  Just the association with the project \"$project_title\"</em></blockquote>
 [ad_footer]"
}

