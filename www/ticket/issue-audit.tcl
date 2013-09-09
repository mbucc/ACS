# /www/ticket/issue-audit.tcl
ad_page_contract {
    View the audit trail for a ticket

    @param msg_id the ID of the ticket to view
    @param mode what mode to operate in.  Not used.
    @param ticket_url not used
    @param return_url not used

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id issue-audit.tcl,v 3.1.2.4 2000/09/22 01:39:23 kevin Exp
} {
    msg_id:integer,notnull
    {mode "full"}
    {ticket_url "/ticket/"}
    {return_url "/ticket/"}
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]

doc_return  200 text/html "
[ad_header "Audit trail of \#$msg_id"]

[ad_audit_trail $msg_id ticket_pretty_audit ticket_pretty msg_id]

[ad_footer]"
