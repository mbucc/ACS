# /www/intranet/hours/ae-2.tcl

ad_page_contract {
    Writes hours to db. 

    @param on_which_table
    @param hours
    @param julian_date

    @author dvr@arsdigita.com
    @author mbryzek@arsdigita.com
    @creation-date Sep 1999

    @cvs-id ae-2.tcl,v 3.5.2.7 2000/08/17 08:30:26 mbryzek Exp

} {
    on_which_table:trim
    hours:array,html
    julian_date
    { return_url "" }
}

set user_id [ad_maybe_redirect_for_registration]

db_transaction {
    foreach name [array names hours] {
	if { ![regsub {\.hours$} $name "" on_what_id] } {
	    continue
	}
	set hours_worked $hours($name)
	if { [empty_string_p $hours_worked] } {
	    set hours_worked 0
	}
	if { [info exists hours(${on_what_id}.note)] } {
	    set note [string trim $hours(${on_what_id}.note)]
	} else {
	    set note ""
	}
	if { [info exists hours(${on_what_id}.billing_rate)] } {
	    set billing_rate $hours(${on_what_id}.billing_rate)
	} else {
	    set billing_rate ""
	}
	if { $hours_worked == 0 && [empty_string_p $note] } {
	    db_dml hours_delete "delete from im_hours
                                  where on_what_id = $on_what_id
                                    and on_which_table = :on_which_table
                                    and user_id = :user_id
                                    and day = to_date(:julian_date, 'J')"
	} else {
            db_dml hours_update "update im_hours
                                    set hours = :hours_worked,
                                        note = :note,
                                        billing_rate = :billing_rate
                                  where on_what_id = :on_what_id
                                    and on_which_table = :on_which_table
                                    and user_id = :user_id
                                    and day = to_date(:julian_date, 'J')"

            if { [db_resultrows] == 0 } {
                db_dml hours_insert "insert into im_hours 
                               (user_id, on_which_table, on_what_id, day, hours, billing_rate, note) 
                               values 
                               (:user_id, :on_which_table, :on_what_id, to_date(:julian_date,'J'), :hours_worked, :billing_rate, :note)"
            }
        }
    }
}

db_release_unused_handles

if { ![empty_string_p $return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect index?[export_url_vars on_which_table julian_date]
}
