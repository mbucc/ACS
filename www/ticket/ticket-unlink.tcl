# /www/ticket/ticket-unlink.tcl
ad_page_contract {
    Removes an entry from the cross-reference table

    @param from_ticket the ticket to remove the x-ref from
    @param to_ticket the ticket to remove the x-ref to 
    @param return_url where to go when we are done

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id ticket-unlink.tcl,v 3.1.6.4 2000/07/21 04:04:35 ron Exp
} { 
    from_ticket:integer,notnull
    to_ticket:integer,notnull
    {return_url "/ticket/"}
}

# -----------------------------------------------------------------------------

db_dml xref_delete "
delete from ticket_xrefs 
where  from_ticket = :from_ticket 
and    to_ticket = :to_ticket"

ad_returnredirect $return_url
