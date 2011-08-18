# $Id: ae-2.tcl,v 3.0.4.2 2000/04/28 15:11:08 carsten Exp $
# File: /www/intranet/hours/ae-2.tcl
#
# Author: dvr@arsdigita.com, Sep 1999
# 
# Writes hours to db. 
#

ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]

set_the_usual_form_variables
# on_which_table
# at least one hours_<id>.<column> field

set db [ns_db gethandle]

foreach var [info vars "hours_*"] {

    if { [regexp {^hours_([0-9]+).*$} $var match on_what_id] } {

	set hours [set hours_${on_what_id}.hours]
	set billing_rate [set hours_${on_what_id}.billing_rate]

        if { [empty_string_p $hours] } {
           set hours 0
        }
        if [empty_string_p $billing_rate] {
           set billing_rate null
        }
        set QQnote [DoubleApos [set hours_${on_what_id}.note]]

        if {($hours == 0) && [empty_string_p $QQnote]} {
            ns_db dml $db "delete from im_hours
                            where on_what_id = $on_what_id
                              and on_which_table = '$QQon_which_table'
                              and user_id = $user_id
                              and day = to_date($julian_date, 'J')"
	} else {

            ns_db dml $db "update im_hours
                              set hours = $hours,
                                  note = '$QQnote',
                                  billing_rate = $billing_rate
                            where on_what_id = $on_what_id
                              and on_which_table = '$QQon_which_table'
                              and user_id = $user_id
                              and day = to_date($julian_date, 'J')"

            if {[ns_ora resultrows $db] == 0} {
                ns_db dml $db "insert into im_hours 
                               (user_id, on_which_table, on_what_id, day, hours, billing_rate, note) 
                               values 
                               ($user_id, '$QQon_which_table', $on_what_id, to_date($julian_date,'J'), $hours, $billing_rate, '$QQnote')"
            }
        }
    }
}

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect index.tcl?[export_url_vars on_which_table julian_date]
}
