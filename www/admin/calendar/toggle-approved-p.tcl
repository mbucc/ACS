# www/calendar/admin/toggle-approved-p.tcl
ad_page_contract {
    This page is called from admin/calendar/item.tcl
    and simply changes the approval flag for the item

    Number of dml: 1

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id toggle-approved-p.tcl,v 3.1.6.4 2000/07/21 03:56:17 ron Exp
    
} {
    calendar_id:naturalnum
}

## Notice the lack of security features, error handling, etc. on this 
## three-line standalone proc.
## The genius of this module continues to inspire me. -MJS 7/20

db_dml toggle "update calendar 
set approved_p = logical_negation(approved_p) 
where calendar_id = :calendar_id"

db_release_unused_handles

ad_returnredirect "item.tcl?calendar_id=$calendar_id"

## END FILE toggle-approved-p.tcl
