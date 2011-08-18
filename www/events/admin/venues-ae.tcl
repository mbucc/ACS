set db [ns_db gethandle]

set_the_usual_form_variables 0
#venue_id if we're editing, return_url if we're adding

ReturnHeaders
if {[info exists venue_id] && ![empty_string_p $venue_id]} {
    #we're editing
    set title "Update a  Venue"
    set submit_text "Update Venue"
    set selection [ns_db 1row $db "select venue_name, address1, address2, 
    city, usps_abbrev, postal_code, iso, needs_reserve_p, max_people,
    description
    from events_venues
    where venue_id = $venue_id"]
    set_variables_after_query
} else {
    set title "Add a New Venue"
    set submit_text "Add Venue"
    set venue_id [database_to_tcl_string $db "select events_venues_id_sequence.nextval from dual"]
    set venue_name ""
    set address1 ""
    set address2 ""
    set city ""
    set usps_abbrev ""
    set postal_code ""
    set iso ""
    set needs_reserve_p "f"
    set max_people ""
    set description ""    
}


ns_write "[ad_header "$title"]
<h2>$title</h2>

[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "venues.tcl" "Venues"] "Venue"]

<hr>
<form method=post action=\"venues-ae-2.tcl\">
<input type=hidden name=venue_id value=\"$venue_id\">
[export_form_vars venue_id return_url]

<table cellpadding=5>
<tr>
 <td>Venue Name:
 <td><input type=text size=20 name=venue_name value=\"$venue_name\">
<tr>
 <td>Address 1:
 <td><input type=text size=50 name=address1 value=\"$address1\">
<tr>
 <td>Address 2:
 <td><input type=text size=50 name=address2 value=\"$address2\">
<tr>
 <td>City:
 <td><input type=text size=50 name=city value=\"$city\">
<tr>
 <td>State:
 <td><input type=text size=2 name=usps_abbrev value=\"$usps_abbrev\">
<tr>
 <td>Zip Code:
 <td><input type=text size=20 name=postal_code value=\"$postal_code\">
<tr>
 <td>Country:
 <td>[country_widget $db us iso $iso]
<tr>
 <td>Maximum Capacity:
 <td><input type=text size=20 name=max_people value=\"$max_people\">
<tr>
 <td>Needs Reservation?
 <td>"
if {[string compare $needs_reserve_p "t"] == 0} {
    set rbox "<input type=checkbox checked name=needs_reserve_p value=\"t\">"
} else {
    set rbox "<input type=checkbox name=needs_reserve_p value=\"t\">"
}
ns_write "$rbox
<tr>
 <td>Description<br>(Include directions)
 <td><textarea name=description rows=8 cols=70 wrap=soft>$description</textarea>
</table>
<p>
<center><input type=submit value=\"$submit_text\"></center>
[ad_footer]
"