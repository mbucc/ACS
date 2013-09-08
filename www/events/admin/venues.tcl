# File:  events/admin/venues.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Add a new venue.  
#####

ad_page_contract {
    Lists event venues.

    @param orderby for ad_table

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id venues.tcl,v 3.10.2.5 2000/09/22 01:37:40 kevin Exp
} {
    {orderby "venue_name"}
}

set whole_page ""
append whole_page "[ad_header "Venues"]"

append whole_page "
<h2>Venues</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Venues"]
<hr>

<ul>
<li><a href=\"venues-ae\">Add a new venue</a>
</ul>
<p>
"

#the columns for ad_table
set col [list venue_name city state country_name]

set table_def {
    {venue_name "Venue Name" {} {<td><a href=\"venues-ae.tcl?[export_url_vars venue_id]\">$venue_name</a></td>}}
    {city "City" {} {<td>$city</td>}}
    {state "State" {} {<td>$state</td>}}
    {country_name "Country" {} {<td>$country_name</td>}}
}

set sql "select
v.venue_id, v.venue_name, v.city,
v.usps_abbrev as state, cc.country_name
from events_venues v, country_codes cc
where v.iso = cc.iso
[ad_order_by_from_sort_spec $orderby $table_def]
"

append whole_page "
[ad_table -Tcolumns $col -Tmissing_text "<em>There are no venues to display</em>" -Torderby $orderby venues_list $sql $table_def]

[ad_footer]
"
## clean up, return.



doc_return  200 text/html $whole_page
##### EOF
