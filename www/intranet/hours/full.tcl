# $Id: full.tcl,v 3.1.4.1 2000/03/17 08:22:56 mbryzek Exp $
# File: /www/intranet/hours/full.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Shows a detailed list of all the hours one user 
# spent on a given item (e.g. a project)
# 

set_the_usual_form_variables
# on_which_table on_what_id user_id show_notes_p
# item (optional - used for UI)

set caller_id [ad_verify_and_get_user_id]

if {![info exists user_id] && ($caller_id != 0)} {
    set looking_at_self_p 1
    set user_id $caller_id
} else {
    if {$caller_id == $user_id} {
        set looking_at_self_p 1
    } else {
        set looking_at_self_p 0
    }
}
set db [ns_db gethandle]

set user_name [database_to_tcl_string $db "\
	select first_names || ' ' || last_name from users where user_id = $user_id"]

if { [exists_and_not_null item] } {
    set page_title "Hours on \"$item\" by $user_name"
} else {
    set page_title "Hours by $user_name"
}

set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list projects.tcl?[export_url_vars on_which_table] "View employee's hours"] [list projects.tcl?[export_url_vars on_which_table user_id] "One employee"] "One project"]

set page_body "<ul>\n"

set selection [ns_db select $db "\
select 
    to_char(day,'fmDay, fmMonth fmDD') as pretty_day,
    to_char(day, 'J') as j_day,
    hours, 
    billing_rate,
    hours * billing_rate as amount_earned, 
    note 
from im_hours
where on_what_id = $on_what_id 
and on_which_table = '$QQon_which_table'
and user_id = $user_id
and hours is not null
order by day"]

set total_hours_on_project 0
set total_hours_billed_hourly 0
set hourly_bill 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append page_body "<p><li>$pretty_day <br><em>$hours [util_decode $hours 1 hour hours]</em>\n"

    set total_hours_on_project [expr $total_hours_on_project + $hours]

    if ![empty_string_p $amount_earned] {
        append page_body " (@ \$[format %4.2f $billing_rate]/hour = \$[format %4.2f $amount_earned])"
        set hourly_bill [expr $hourly_bill + $amount_earned]
        set total_hours_billed_hourly [expr $total_hours_billed_hourly + $hours]
    }

    if ![empty_string_p $note] {
        append page_body "<blockquote>$note</blockquote>"
    }
}

append page_body "\n<p><b>Total:</b> [util_commify_number $total_hours_on_project] 
[util_decode $total_hours_on_project 1 hour hours]"

if {$hourly_bill > 0} {
    append page_body "<BR><FONT SIZE=-1>[util_commify_number $total_hours_billed_hourly]
of those hours were billed hourly, for a total amount of 
\$[util_commify_number [format %4.2f $hourly_bill]]</FONT>"
}

append page_body "</ul>\n"

ns_return 200 text/html [ad_partner_return_template]
