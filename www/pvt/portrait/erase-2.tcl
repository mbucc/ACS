# /pvt/portrait/erase-2.tcl

ad_page_contract {
    erase's a user's portrait (NULLs out columns in the database)
    
    @param operation Must be set to "Yes, I'm sure" (case-insensitive) for portrait to be erased

    @author philg@mit.edu
    @creation-date September 26, 1999
    @cvs-id erase-2.tcl,v 3.1.8.3 2000/08/27 19:52:10 mbryzek Exp
} {
    { operation:trim "" }
    { return_url "" }
}

# delete from general_portraits if the user confirmed

if { [string equal [string toupper $operation] "YES, I'M SURE"] } {
    set user_id [ad_maybe_redirect_for_registration]

    db_dml portrait_erase {
	delete from general_portraits
	where on_what_id = :user_id
	and on_which_table = 'USERS'
	and approved_p = 't'
	and portrait_primary_p = 't'
    }
    # default return_url to user home page (portrait/index is only for
    # people with portaits)

    if { [empty_string_p $return_url] } {
	set return_url [ad_pvt_home]
    }
} else {
    # Go back to the portrait management page (unless return_url was specified)
    if { [empty_string_p $return_url] } {
	set return_url "index"
    }
}

ad_returnredirect $return_url
