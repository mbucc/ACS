# $Id: project-close.tcl,v 3.0.4.1 2000/04/28 15:11:37 carsten Exp $
ad_page_variables {
    project_id
    {reopen 0}
    {return_url {/ticket/admin/}}
}

set db [ns_db gethandle]
set user_id [ad_get_user_id]

if {$reopen} {
    ns_db dml $db "update ticket_projects set end_date = null where project_id = $project_id"
} else { 
    ns_db dml $db "update ticket_projects set end_date = sysdate where project_id = $project_id"
}

ad_returnredirect $return_url
