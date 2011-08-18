# $Id: issue-audit.tcl,v 3.0 2000/02/06 03:06:23 ron Exp $
ad_page_variables {msg_id 
    {mode full}
    {ticket_url {/ticket/}}
    {return_url {/ticket/}}
}


set db [ns_db gethandle]
set user_id [ad_get_user_id]

ReturnHeaders 

ns_write "[ad_header "Audit trail of \#$msg_id"]
 [ad_audit_trail $db $msg_id ticket_pretty_audit ticket_pretty msg_id]
 [ad_footer]"
