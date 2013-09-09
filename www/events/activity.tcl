# events/activity.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Takes in an activity_id, displays the related activity
#           to the user and shows all upcoming events for this activity.
#####

ad_page_contract {
    Takes in an activity_id, displays the related activity
    to the user and shows all upcoming events for this activity.
    
    @param activity_id the activity in which we're interested

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id activity.tcl,v 3.10.6.5 2000/09/22 01:37:32 kevin Exp
} {
    {activity_id:integer,notnull}
}

set activity_check [db_0or1row sel_activity_info "select 
	a.short_name, a.description, a.detail_url, a.available_p
   from events_activities a
  where  activity_id = :activity_id"]

if {!$activity_check} {
    db_release_unused_handles
    ad_return_warning "Could not find activity" "We can't tell you 
    what this activity is going to be like because we
    can't find activity $activity_id in the database."
    return
}

# else we have a valid activity id

if { $available_p == "f" } {
    db_release_unused_handles
    # activity has been discontinued
    ad_return_warning "Activity Discontinued" "$short_name 
    is no longer available.  You're
    probably using an old bookmarked page."
    return
}

# else we're here and we've got all the relevant stuff

#if [regexp -nocase {^http://.*} $detail_url] {
#    ns_log Notice "event.tcl trying to fetch $detail_url"
    # we have to go to a foreign server to get the stuff
#    if [catch { set raw_foreign_page [ns_httpget $detail_url] } errmsg] {
	# we got an error fetching the page
#	ns_log Notice "activity.tcl failed to get $detail_url for activity $activity_id"
#    } else {
#	regexp -nocase {<body>(.*)</body>} $raw_foreign_page match fancy_promo_text
#    }
#} 

#if { ![info exists fancy_promo_text] && ![regexp -nocase {^http://.*} $detail_url] } {
#    ns_log Notice "event.tcl trying to pull $detail_url from the local file system"
    # let's try to pull it from our file system
#    if [catch { append full_file_name [ns_info pageroot] $detail_url
#                set stream [open $full_file_name r]
#                set raw_local_page [read $stream]
#                close $stream
#              } errmsg] {
	# we got an error fetching the page
#	ns_log Notice "activity.tcl failed to read $full_file_name for activity $activity_id"
#    } else {
#	regexp -nocase {<body[^>]*>(.*)</body>} $raw_local_page match fancy_promo_text
#    }
#}

if { ![info exists fancy_promo_text] } {
    # nothing fancy passed in.
    # let's construct a generic page from what was in the database
    set fancy_promo_text "
<h2>$short_name</h2>
[ad_context_bar_ws [list "index.tcl" "Events"] "Activity"]
<hr>

$description
"

set table_rows ""

# let's display the upcoming events for this activity
db_foreach evnt_upcoming_evnts "select 
	e.event_id, 
	v.city, 
        decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location,
	e.start_time, 
	to_char(e.start_time,'fmDay') as pretty_day,
	to_char(e.start_time,'HH12:MI AM') as pretty_start_hour_minute
   from events_events e, events_activities a, events_venues v, country_codes cc
  where a.activity_id = e.activity_id
    and a.activity_id = :activity_id
    and e.start_time > sysdate
    and e.available_p <> 'f'
    and v.venue_id = e.venue_id
    and cc.iso = v.iso
  order by e.start_time" {
	append table_rows "
	<tr>
	 <td><a href=\"order-one?event_id=$event_id\">$city, $big_location
         <td>$pretty_day, [util_AnsiDatetoPrettyDate $start_time]\n
	"
    }

if ![empty_string_p $table_rows] {
    append fancy_promo_text " <h3>Upcoming Events</h3>
<table cellspacing=15>
 $table_rows
</table>\n"
   } else {
    append fancy_promo_text " <br><blockquote> 
       No upcoming events. </blockquote>"
   }
}

## Release everything; clean up



doc_return  200 text/html "[ad_header "$short_name"] \n $fancy_promo_text \n [ad_footer]"

##### File Over.
