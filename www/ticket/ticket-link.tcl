# $Id: ticket-link.tcl,v 3.0.4.1 2000/04/28 15:11:35 carsten Exp $
ad_page_variables { 
    from_ticket
    to_ticket
    {return_url {/ticket/}}
}

if {! [regexp {^[0-9]+$} $from_ticket]
    || ! [regexp {^[0-9]+$} $to_ticket]} { 
    ad_return_complaint 1 "<LI> Invalid ticket IDs when creating link."
    return
}

set db [ns_db gethandle]

if {[catch {ns_db dml $db "insert into ticket_xrefs(from_ticket, to_ticket) values ($from_ticket, $to_ticket)"} errmsg]} {
    ad_return_complaint 1 "<LI> I could not link tickets $from_ticket and $to_ticket.  Check that you provided a valid ticket \# and the link does not already exist.<pre>$errmsg</pre>"
    return
}
    
ad_returnredirect $return_url
