ad_library {
    Definitions related to getting information about a user

    @author Philip Greenspun (philg@mit.edu)
    @cvs-id ad-user.tcl,v 3.0.14.1 2000/07/13 19:43:17 dharris Exp
    @creation-date October 31, 1999
}

ad_proc ad_user_contact_info_display_var_p {varname} {
    set varname_exclusion_patterns [list "user_id" "m_address" "priv_*"]
    foreach pattern $varname_exclusion_patterns {
	if [string match $pattern $varname] {
	    return 0
	}
    }
    # didn't match a pattern; good to print out
    return 1
}

ad_proc ad_user_contact_info {user_id {user_class "public"}} {Returns an HTML fragment of an appropriate amount of contact info for a user, depending on the user's privacy settings and who is logged in } {

    # Because of the nature of the contact info and the bulk of columns
    # we'll keep the old way of using database result manipulation
    db_with_handle db {
	if [catch { set selection [ns_db 1row $db "select * from users_contact where user_id = $user_id"] } ] {
	    # probably this is an ACS where the table isn't defined
	    return ""
	} else {
	    # table exists and this user has an entry
	    set_variables_after_query
	}
    }

    # We can't have gotten here w/o variables being set since
    # the catch on the query returns an empty string on error

    set contact_items ""
    for {set i 0} {$i<[ns_set size $selection]} {incr i} {
	set varname [ns_set key $selection $i]
	set varvalue [ns_set value $selection $i]
	if { ![empty_string_p $varvalue] && [ad_user_contact_info_display_var_p $varname] } {
	    if { $user_class != "site_admin" } {
		# let's look for a priv_ value 
		if { ![info exists "priv_$varname"] || [empty_string_p [set "priv_$varname"]] } {
		    # don't find a control, assume it is private
		    continue
		} else {
		    # there is a privacy value
		    if { [set "priv_$varname"] > [ad_privacy_threshold] } {
			# user wants more privacy than currently connected user warrants
			continue
		    }
		}
	    }
	    append contact_items "<li>$varname: $varvalue\n"
	}
    }
    if ![empty_string_p $contact_items] {
	return "<ul>\n\n$contact_items\n\n</ul>\n"
    } else {
	return ""
    }
}

