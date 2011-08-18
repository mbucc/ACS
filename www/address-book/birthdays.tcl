# $Id: birthdays.tcl,v 3.0 2000/02/06 02:44:21 ron Exp $
# File:     /address-book/record-search.tcl
# Date:     12/24/99
# Contact:  teadams@arsdigita.com, tarik@arsdigita.com
# Purpose:  shows a single address book record
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe contact_info_only
# maybe order_by

ad_scope_error_check user

set db [ns_db gethandle]
ad_scope_authorize $db $scope none group_member user

set name [address_book_name $db]


ReturnHeaders
ns_write "
[ad_scope_header "Birthdays" $db]
[ad_scope_page_title "Birthdays" $db ]
[ad_scope_context_bar_ws [list "index.tcl?[export_ns_set_vars]" "Address book"] "Birthdays"]
<hr>
[ad_scope_navbar]
"

# this is for my ordering scheme described below
set date_format "MMDDYYYY"
set this_year [database_to_tcl_string $db "select to_char(sysdate,'YYYY') from dual"]
set a_leap_year "1996"
set this_date_in_a_leap_year "[database_to_tcl_string $db "select to_char(sysdate, 'MMDD') from dual"]$a_leap_year"

# the crazy-looking ordering below was chosen so that if someone's birthday is today, it will show up first, then we'll see people who have birthdays coming up this year (in chronological order), then we'll see people whose next birthday won't be until next year (in chronological order)

set selection [ns_db select $db "select address_book_id, first_names, last_name, birthmonth, birthday, birthyear, sign(to_date('$this_date_in_a_leap_year','$date_format')-to_date(birthmonth || birthday || '$a_leap_year','$date_format')) as before_or_after_today, to_char(to_date(birthmonth,'MM'),'Mon') as pretty_birthmonth
from address_book 
where [ad_scope_sql] and birthmonth is not null
order by abs(sign(to_date('$this_date_in_a_leap_year','$date_format')-to_date(birthmonth || birthday || '$a_leap_year','$date_format'))),
sign(to_date('$this_date_in_a_leap_year','$date_format')-to_date(birthmonth || birthday || '$a_leap_year','$date_format')), 
to_date(birthmonth || birthday || '$a_leap_year','$date_format')-to_date('$this_date_in_a_leap_year','$date_format')"]

set count 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr count
    # if $before_or_after_today = -1 then the birthday is later in the year than today, if it's 0 then it's today, if 1 then it won't occur until next year

    append html "$pretty_birthmonth $birthday: <a href=record.tcl?[export_url_scope_vars address_book_id]>$first_names $last_name</a>"

    if { $birthyear != "" } {
	if { $before_or_after_today == "0" } {
	    set age_on_next_birthday [expr $this_year - $birthyear]
	    append html " (turns $age_on_next_birthday today!)"
	} elseif { $before_or_after_today == "-1" } {
	    set age_on_next_birthday [expr $this_year - $birthyear]
	    append html " (turns $age_on_next_birthday)"
	} else {
	    set age_on_next_birthday [expr $this_year + 1 - $birthyear]
	    append html " (turns $age_on_next_birthday)"
	}
    }

    append html "<br>"
}

if {$count == 0 } {
    append html "No birthdays have been entered."
}

ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_footer]
"
