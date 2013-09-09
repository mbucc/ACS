# File:  events/admin/venues-ae-2.tcl
# Owner: bryanche@arsdigita.com
# Purpose:  Add or edit a venue.
#####

ad_page_contract {
    Add or edit a venue.

    @param venue_id the venue_id
    @param venue_name the venue's name
    @param address1 venue address
    @param address2 venue address
    @param city venue city (required)
    @param usps_abbrev venue's state
    @param postal_code venue's postal code
    @param iso venue's country code
    @param needs_reserve_p does this venue need a reservation
    @param description the venue's description
    @param fax_number the venue's fax number
    @param phone_number the venue's phone number
    @param email the venune's e-mail address
    @param optional return url if adding a venue

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id venues-ae-2.tcl,v 3.9.2.6 2001/01/10 18:14:55 khy Exp
} {
    {venue_id:naturalnum,verify}
    {venue_name:trim,notnull}
    {address1:trim,optional}
    {address2:trim,optional}
    {city:trim,notnull}
    {usps_abbrev}
    {postal_code:trim,optional}
    {iso:notnull}
    {needs_reserve_p "f"}
    {max_people:naturalnum,optional}
    {description:html,optional}
    {fax_number:optional}
    {phone_number:optional}
    {email:optional}
    {return_url:trim,optional [db_null]}
}


### Error checking
set exception_text ""
set exception_count 0

if {[string compare $iso "us"] == 0} {
    if {![info exists usps_abbrev] || [empty_string_p $usps_abbrev]} {
	incr exception_count
	append exception_text "<li>You must enter a state"
    }
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

db_transaction {

db_dml unused "update events_venues set
 venue_name=:venue_name,
 address1=:address1,
 address2=:address2,
 city=:city,
 usps_abbrev=:usps_abbrev,
 postal_code=:postal_code,
 iso=:iso,
 needs_reserve_p=:needs_reserve_p,
 max_people=:max_people,
 description=:description,
 fax_number = :fax_number,
 phone_number = :phone_number,
 email = :email
where venue_id=:venue_id" 

if {[db_resultrows] == 0} {
    db_dml unused "insert into events_venues
    (venue_id, venue_name, address1, address2, city, usps_abbrev, postal_code,
     iso, needs_reserve_p, max_people, description, fax_number, phone_number,
     email)
    values
    (:venue_id, :venue_name, :address1, :address2, :city,
     :usps_abbrev, :postal_code, :iso, :needs_reserve_p,
      :max_people, :description, :fax_number, :phone_number,
     :email)" 
}

}

if {[info exists return_url] && ![empty_string_p $return_url]} {
    ad_returnredirect "$return_url&[export_url_vars venue_id]"
} else {
    ad_returnredirect "venues.tcl"
}

##### EOF
