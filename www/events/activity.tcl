set_the_usual_form_variables 0

# activity_id

if { ![info exists activity_id] || $activity_id == "" } {
    ns_return 200 text/html "[ad_header "No activity id"]

<h2>No activity id</h2>

specified for [ad_system_name]

<hr>

We can't tell you what this activity is going to be like because this
request came in with no activity id.  Please notify the maintainer of
the preceding page.

[ad_footer]
"
    return
}


set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select 
a.short_name, a.description, a.detail_url, a.available_p
from events_activities a
where activity_id = $activity_id"]

if { $selection == "" } {
    ns_db releasehandle $db
    ns_return 200 text/html "[ad_header "Could not find activity"]

<h2>Could not find activity</h2>

in [ad_system_name]

<hr>

We can't tell you what this activity is going to be like because we
can't find activity $activity_id in the database.  Please notify the
maintainer of the preceding page.

[ad_footer]
"
    return
}

# we have a valid activity id

set_variables_after_query

# we have all the description info from the RDBMS

if { $available_p == "f" } {
    ns_db releasehandle $db
    # activity has been discontinued
     ns_return 200 text/html "[ad_header "Activity Discontinued"]

<h2>Activity Discontinued</h2>

in [ad_system_name]

<hr>

$short_name is no longer available.  You're
probably using an old bookmarked page.

[ad_footer]
"
    return
}

# we're here and we've got all the relevant stuff

if [regexp -nocase {^http://.*} $detail_url] {
    ns_log Notice "event.tcl trying to fetch $detail_url"
    # we have to go to a foreign server to get the stuff
    if [catch { set raw_foreign_page [ns_httpget $detail_url] } errmsg] {
	# we got an error fetching the page
	ns_log Notice "event.tcl failed to get $detail_url for event $event_id"
    } else {
	regexp -nocase {<body>(.*)</body>} $raw_foreign_page match fancy_promo_text
    }
} 

if { ![info exists fancy_promo_text] && ![regexp -nocase {^http://.*} $detail_url] } {
    ns_log Notice "event.tcl trying to pull $detail_url from the local file system"
    # let's try to pull it from our file system
    if [catch { append full_file_name [ns_info pageroot] $detail_url
                set stream [open $full_file_name r]
                set raw_local_page [read $stream]
                close $stream
              } errmsg] {
	# we got an error fetching the page
	ns_log Notice "event.tcl failed to read $full_file_name for event $event_id"
    } else {
	regexp -nocase {<body[^>]*>(.*)</body>} $raw_local_page match fancy_promo_text
    }
}

if { ![info exists fancy_promo_text] } {
    # let's construct a generic page from what was in the database
    set fancy_promo_text "<h2>$short_name</h2>
<hr>
$description
"

ns_db releasehandle $db

set db_pools [ns_db gethandle subquery 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

# let's display the upcoming events for this activity
set selection [ns_db select $db "select 
e.event_id, 
v.city, 
v.usps_abbrev, 
v.iso,
e.start_time, 
to_char(e.start_time,'fmDay') as pretty_day,
to_char(e.start_time,'HH12:MI AM') as pretty_start_hour_minute
from events_events e, events_activities a, events_venues v
where a.activity_id = e.activity_id
and a.activity_id = $activity_id
and e.start_time > sysdate
and e.available_p <> 'f'
and v.venue_id = e.venue_id
order by e.start_time"]
    set table_rows ""
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append table_rows "
	<tr>
	 <td><a href=\"order-one.tcl?event_id=$event_id\">
 	 [events_pretty_location $db_sub $city $usps_abbrev $iso]</a>
         <td>$pretty_day, [util_AnsiDatetoPrettyDate $start_time]\n"
    }
    if ![empty_string_p $table_rows] {
    append fancy_promo_text "
<h3>Upcoming Events</h3>
<table cellspacing=15>
$table_rows
</table>\n"
    }
}

ns_db releasehandle $db
ns_db releasehandle $db_sub

ReturnHeaders

ns_write "[ad_header "$short_name"]

$fancy_promo_text
[ad_footer]
"
