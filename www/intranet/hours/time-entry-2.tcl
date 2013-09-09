# /www/intranet/hours/time-entry-2.tcl

ad_page_contract {

    Writes hours to db

    @param on_which_table the table we're logging hours for
    @param hours array of (on_what_id_julian_date_<hours|note>)
    @param old_hours array of (on_what_id_julian_date_<hours|note>)
    @param user_id User for which we're editing hours. Defaults to currently logged in user

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date July 2, 2000
    @cvs-id time-entry-2.tcl,v 3.1.2.8 2000/08/17 08:30:26 mbryzek Exp
   
} {
    on_which_table
    hours:array,html
    old_hours:array,html
    { user_id:integer "" }
    { return_url "" }
}


proc_doc im_hours_form_var { array_name var_name { default "" } } {
    Formats the value of the specified var_name in array_name,
    returning default if it doesn't exist or is empty 
} {
    upvar $array_name array
    if { [info exists array($var_name)] } {
	set value [string trim [set array($var_name)]]
	if { ![empty_string_p $value] } {
	    return $value
	}
    }
    return $default
}

# Default user_id... im_hours_verify_user_id will return the correct 
# one for this page
set user_id [im_hours_verify_user_id $user_id]

db_transaction {
    foreach name [array names hours] {
	if { ![regexp {^([0-9]+)\.([0-9]+)\.hours$} $name match on_what_id julian_date] } {
	    continue
	}
	set base_var "${on_what_id}.${julian_date}"
	set hours_worked [im_hours_form_var hours "$base_var.hours" 0]
	set old_hours_worked [im_hours_form_var old_hours "$base_var.hours" 0]
	set note [im_hours_form_var hours "$base_var.notes"]
	set old_note [im_hours_form_var old_hours "$base_var.notes"]
	
	if { $hours_worked == $old_hours_worked && [string compare $note $old_note] == 0 } {
	    # Nothing has changed!
	    continue;
	}

	# Ensure hours are less than 24 and greater than 0
	# (Also gets non-numeric strings)
	if { $hours_worked > 24 || $hours_worked < 0} {
	    db_abort_transaction
	    ad_return_complaint 1 "  <li> Your hours must be a number between 0 and 24."
	    return
	}

	# something has changed... first check if we should delete
	if { $hours_worked == 0 && [empty_string_p $note] } {
	    db_dml hours_delete "delete from im_hours
                                  where on_what_id = $on_what_id
                                    and on_which_table = :on_which_table
                                    and user_id = :user_id
                                    and day = to_date(:julian_date, 'J')"

	} else {
	    # Update first... then maybe insert

            db_dml hours_update "update im_hours
                                    set hours = :hours_worked,
                                        note = :note
                                  where on_what_id = :on_what_id
                                    and on_which_table = :on_which_table
                                    and user_id = :user_id
                                    and day = to_date(:julian_date, 'J')"

            if { [db_resultrows] == 0 } {
                db_dml hours_insert "insert into im_hours 
                               (user_id, on_which_table, on_what_id, day, hours, note) 
                               values 
                               (:user_id, :on_which_table, :on_what_id, to_date(:julian_date,'J'), :hours_worked, :note)"
            }
        }
    }
}

db_release_unused_handles

if { ![empty_string_p $return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect index?[export_url_vars user_id on_which_table julian_date]
}
