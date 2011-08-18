# $Id: ad-geospatial.tcl,v 3.0 2000/02/06 03:12:23 ron Exp $
# created by philg@mit.edu on 11/19/98
# stuff having to do with 

proc_doc ad_state_name_from_usps_abbrev {db usps_abbrev} "Takes a database connection and a USPS abbrevation and returns the full state name, e.g., MA in yields Massachusetts out" {
    return [database_to_tcl_string_or_null $db "select state_name from states where usps_abbrev ='[DoubleApos $usps_abbrev]'" $usps_abbrev]
}


proc_doc ad_country_name_from_country_code {db country_code} {Returns "United States" from an argument of $db and "us"} {
    return [database_to_tcl_string_or_null $db "select country_name from country_codes where iso='[DoubleApos $country_code]'" $country_code]
}
