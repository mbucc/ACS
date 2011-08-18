# $Id: ticket-close.tcl,v 3.0.4.1 2000/04/28 15:11:35 carsten Exp $
ad_page_variables {
    msg_id
    what
    value
    {reopen 0}
    {return_url {/ticket/}}
}

set db [ns_db gethandle]
set user_id [ad_get_user_id]

# given a what (code_type) we look up the value and set it on the 
# ticket
util_dbq value
set selection [ns_db 0or1row $db "select code_id from ticket_codes tc, ticket_issues ti, ticket_projects tp where ti.msg_id = $msg_id and tp.project_id  = ti.project_id and tp.code_set = tc.code_set and code = $DBQvalue"]

if {[empty_string_p selection]} { 
    ad_return_complaint 1 "<LI> TR\#$msg_id does not have a code for $what:$value"
    return
}

set_variables_after_query

ns_db dml $db "update ticket_issues_i set ${what}_id = $code_id where msg_id = $msg_id"

ad_returnredirect $return_url
