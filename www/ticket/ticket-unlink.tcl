# $Id: ticket-unlink.tcl,v 3.0.4.1 2000/04/28 15:11:35 carsten Exp $
#
# remove an entry from the  cross-reference table
#
# from_msg_id
# to_msg_id
# target

ad_page_variables { 
    from_ticket
    to_ticket
    {return_url {/ticket/}}
}

if {! [regexp {^[0-9]+$} $from_ticket]
    || ! [regexp {^[0-9]+$} $to_ticket]} { 
    ad_return_complaint 1 "<LI> Invalid ticket IDs when unlinking."
    return
}

set db [ns_db gethandle]

ns_db dml $db "delete from ticket_xrefs where from_ticket = $from_ticket and to_ticket = $to_ticket"

ad_returnredirect $return_url
