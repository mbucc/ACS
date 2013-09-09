ad_page_contract {
    deletes a venue

    @param venue_id the venue to be deleted

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id venue-delete.tcl,v 3.1.2.4 2000/07/21 03:59:41 ron Exp
} {
    {venue_id:integer,notnull}
}

if {[catch {db_dml venue_delete "delete from events_venues where venue_id = :venue_id"} errmsg]} {
    #see if this failed because there are events using this venue
    set event_count [db_string event_count "select
    count(*) 
    from events_events
    where venue_id = :venue_id"]
    if {$event_count > 0} {
	db_release_unused_handles

	ad_return_warning "Venue in Use" "This venue is being
	used by one or more events.  You cannot delete this
	venue unless no events are located there."
	return
    } else {
	
	db_release_unused_handles
	
	ad_return_error "Could Not Delete Venue" "We were unable to delete
	this venue.  Here is the error from the database:
	<p>
	<pre>
	$errmsg
	</pre>"
	return
    }
}

db_release_unused_handles
ad_returnredirect "venues.tcl"

