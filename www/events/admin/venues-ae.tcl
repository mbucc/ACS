# File:  events/admin/venues-ae.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Add or edit a venue.
#####

ad_page_contract {
    Add or edit a venue.
    
    @param venue_id the venue if we're editing a venue
    @param return_url the return url if we're adding a venue

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id venues-ae.tcl,v 3.9.2.6 2001/01/10 18:13:28 khy Exp
} {
    {venue_id:integer,optional}
    {return_url:optional}
}

set whole_page ""

if {[info exists venue_id] && ![empty_string_p $venue_id]} {
    #we're editing
    set title "Update a Venue"
    set submit_text "Update Venue"
    db_1row venue_info "select venue_name, address1, address2, 
    city, usps_abbrev, postal_code, iso, needs_reserve_p, max_people,
    description, fax_number, phone_number, email
    from events_venues
    where venue_id = :venue_id"

    set header "Delete Venue"
    set message "Are you sure you want to delete this venue?"

    set yes_url "/events/admin/venue-delete.tcl?[export_url_vars venue_id]"
    set no_url "/events/admin/venues.tcl"

    set delete_html "
    <h2>Delete This Venue</h2>
    <ul>
    <li>You may also
    <a href=\"/shared/confirm?[export_url_vars header message yes_url no_url]\">delete this venue</a>. 
    </ul>"
} else {
    set title "Add a New Venue"
    set submit_text "Add Venue"
    set venue_id [db_string get_venue_id "select events_venues_id_sequence.nextval from dual"]
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
    set fax_number ""
    set phone_number ""
    set email ""

    set delete_html ""
}

append whole_page "
  [ad_header "$title"]
<h2>$title</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] [list "venues.tcl" "Venues"] "Venue"]
<hr>

<form method=post action=\"venues-ae-2.tcl\">
[export_form_vars return_url]
[export_form_vars -sign venue_id]
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
 <td>[events_state_widget "$usps_abbrev" 1 "usps_abbrev"]
<tr>
 <td>Zip Code:
 <td><input type=text size=20 name=postal_code value=\"$postal_code\">
<tr>
 <td>Country:
 <td>[country_widget $iso iso 1]
<tr>
 <td>Phone Number:
 <td><input type=text size=30 name=phone_number value=\"$phone_number\">
<tr>
 <td>Fax Number:
 <td><input type=text size=30 name=fax_number value=\"$fax_number\">
<tr>
 <td>E-mail:
 <td><input type=text size=30 name=email value=\"$email\">
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

append whole_page "$rbox
<tr>
 <td>Description<br>(Include directions)
 <td><textarea name=description rows=8 cols=70 wrap=soft>$description</textarea>
</table>
<p>
<center><input type=submit value=\"$submit_text\"></center>
</form>

$delete_html
[ad_footer]
"

## clean up, return.


doc_return  200 text/html $whole_page
##### EOF
