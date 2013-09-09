# /www/ticket/ticket-link.tcl
ad_page_contract {
    Cross-reference two tickets

    @param from_ticket the ticket to x-reference from
    @param to_ticket the ticket to x-reference to
    @param return_url where to send them when we're done

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id ticket-link.tcl,v 3.1.6.4 2000/07/21 04:04:34 ron Exp
} { 
    from_ticket:integer,notnull
    to_ticket:integer,notnull
    {return_url "/ticket/"}
}

# -----------------------------------------------------------------------------

if {[catch {db_dml xref_insert "
insert into ticket_xrefs(from_ticket, to_ticket) 
values (:from_ticket, :to_ticket)"} errmsg]} {
    ad_return_complaint 1 "<LI> I could not link tickets $from_ticket and $to_ticket.  Check that you provided a valid ticket \# and the link does not already exist.<pre>$errmsg</pre>"
    return
}
    
ad_returnredirect $return_url
