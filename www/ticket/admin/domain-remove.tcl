# /www/ticket/admin/domain-remove.tcl
ad_page_contract {
    Remove a domain from a project

    @param domain_id the ID of the domain to remove
    @param project_id the project to remove it from
    @param force because the page flow is stupid, use this to see
           if they really mean it.
    @param return_url where to go when we're done

    @author Jeff Davis (davis@arsdigita.com) ?
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date ? 3.4 modifications 8 July 2000
    @cvs-id domain-remove.tcl,v 3.2.2.7 2000/10/27 19:26:35 jmileham Exp
} {
    domain_id:integer,notnull 
    project_id:integer,notnull 
    {force:integer 0} 
    {return_url "/ticket/admin/"}
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

if {![db_0or1row find_existing_tickets "
select td.title_long as domain_title, 
       tp.title_long as project_title, 
       tic.n_tickets as n_tickets
from  ticket_domains td, 
      ticket_projects tp, 
      (select domain_id, project_id, count(*) as n_tickets 
        from ticket_issues_i group by domain_id, project_id) tic
where td.domain_id = :domain_id
and   tp.project_id = :project_id
and   tic.domain_id(+) = :domain_id
and   tic.project_id(+) = :project_id"] || $force} {

    # got no rows so nuke away buddy
    db_dml domain_remove "
    delete from ticket_domain_project_map 
    where  domain_id = :domain_id 
    and    project_id = :project_id" 

    ad_returnredirect "$return_url&action_msg=[ns_urlencode {Domain Project mapping deleted}]"

} else {
    set force 1

    doc_return  200 text/html "
[ad_header "Remove Project-Feature Area Mapping"]

<h2>Confirm removal of Project-Feature Area Mapping</h2>

<hr>

<blockquote>
$n_tickets tickets exist for domain \"$domain_title\" 
in project \"$project_title\".<br>

 Remove the association anyway?

<blockquote>

 <form>
[export_form_vars force return_url domain_id project_id]
<input type=submit value=\"Yes\">
</form>
 </blockquote>

 <em>This action will not remove the tickets or the feature area.  
Just the association with the project \"$project_title\"</em>
</blockquote>

 [ad_footer]"
}

