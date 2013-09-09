# /www/tickets/admin/project-close.tcl
ad_page_contract {
    Use this page to close a project (i.e. set the end date to today.)
    Or, use it to reopen a project.

    @param project_id the projects we are closing
    @param reopen are we secretly reopening the project
    @param return_url where to go afterwards

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id project-close.tcl,v 3.1.6.5 2000/07/21 04:04:42 ron Exp
} {
    project_id:integer,notnull
    {reopen 0}
    {return_url "/ticket/admin/"}
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

if {$reopen} {
    db_dml project_reopen "
    update ticket_projects set end_date = NULL 
    where project_id = :project_id" 
} else { 
    db_dml project_close "
    update ticket_projects set end_date = sysdate 
    where project_id = :project_id" 
}

ad_returnredirect $return_url
