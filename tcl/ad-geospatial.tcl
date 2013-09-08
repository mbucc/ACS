ad_library {
    Stuff having to do with geospatialization

    @author Philip Greenspun [philg@arsdigita.com]
    @date 11/19/98
    @cvs-id ad-geospatial.tcl,v 3.1.2.5 2000/07/14 18:24:38 bquinn Exp
}

proc_doc ad_state_name_from_usps_abbrev {usps_abbrev} "Takes a USPS abbrevation and returns the full state name, e.g., MA in yields Massachusetts out" {
    return [db_string state_name_from_usps_abbrev {
	select state_name from states where usps_abbrev =:usps_abbrev
    } -default ""]
}

proc_doc ad_country_name_from_country_code {country_code} {Returns "United States" from an argument of $db and "us"} {
    return [db_string country_name_from_country_code {
	select country_name from country_codes where iso=:country_code
    } -default ""]    
}
