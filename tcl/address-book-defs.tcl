# $Id: address-book-defs.tcl,v 3.0 2000/02/06 03:12:56 ron Exp $
proc address_book_url { } {
    return "/address-book/"
}

proc_doc address_book_authorized {scope db {group_id 0}} "If scope=0, return 1 if the user is authorized; 0 otherwise. Otherwise, returns 1. This function will expand as we expand the permissions in the address book" {
    # user should be in the group 
    if {$scope=="group" && ![ad_user_group_member $db $group_id]} {
	return 0
    } else {
	return 1
    }
}

proc_doc address_book_name { db } "assumes scope is set in the callers environment. if scope=group it assumes group_id is set in the callers environment, if scope=user it assumes that user_id is set in callers environment. For scope=group, returns the name of the group if the user is authorized. For scope=user, returns the person's name. For scope=public, returns the site name. For scope=table it returns an empty string."  {
    upvar scope scope 

    switch $scope {
	"public" {
	    return [ad_system_name]
	}
	"group" {
	    upvar group_id group_id
	    return [database_to_tcl_string $db "select group_name from user_groups where group_id = $group_id"]
	}
	"user" {
	    upvar user_id user_id
	    return [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = [ad_get_user_id]"]
	}
	"table" {
	    return ""
	}
    }
}

proc_doc address_book_record_display { selection {contact_info_only "f"} } "Displays address in a plain text manner.  Wrap the output in address_book_display_as_html for display on web site."  {

    set_variables_after_query
    set to_return "$first_names $last_name"
    foreach column [list email email2] {
	if { [string compare [set $column] ""] != 0 } {
	    append to_return "<br><a href=mailto:[set $column]>[set $column]</a>"
	}

    }
    foreach column [list line1 line2] {
	if { [string compare [set $column] ""] != 0 } {
	    append to_return "<br>[set $column]"
	}
    }

    if { [string compare $city ""] != 0 } {
	append to_return "<br>$city, $usps_abbrev $zip_code"
    }
    if { [string compare $country ""] != 0 && [string compare $country "USA"] != 0 } {
	append to_return "<br>$country"
    }
    if { [string compare $phone_home ""] != 0 } {
	append to_return "<br>$phone_home (home)"
    }
    if { [string compare $phone_work ""] != 0 } {
	append to_return "<br>$phone_work (work)"
    }
    if { [string compare $phone_cell ""] != 0 } {
	append to_return "<br>$phone_cell (cell)"
    }
    if { [string compare $phone_other ""] != 0 } {
	append to_return "<br>$phone_other (other)"
    }
    if { [string compare $birthmonth ""] != 0 && $contact_info_only == "f" } {
	append to_return "<br>birthday $birthmonth/$birthday"
    }
    if { [string compare $birthyear ""] != 0 && $contact_info_only == "f" } {
	append to_return "/$birthyear"
    }
    if { [string compare $notes ""] != 0 && $contact_info_only == "f" } {
	append to_return "<br>\[$notes\]"
    }
 
    return $to_return
}

proc address_book_birthday_widget { {birthmonth ""} {birthday ""} {birthyear ""} } {
    set to_return "Month <select name=birthmonth>\n<option value=\"\">\n"
    set monthlist [list "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12"]
    set daylist [list "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31"]
    foreach month $monthlist {
	if { $month == $birthmonth } {
	    append to_return "<option value\"$month\" selected>$month\n"
	} else {
	    append to_return "<option value\"$month\">$month\n"
	}
    }
    append to_return "</select><br>Day <select name=birthday>\n<option value=\"\">\n"
    foreach day $daylist {
	if { $day == $birthday } {
	    append to_return "<option value\"$day\" selected>$day\n"
	} else {
	    append to_return "<option value\"$day\">$day\n"
	}
    }
    append to_return "</select><br>Year <input type=text name=birthyear size=4 value=\"$birthyear\">"
    return $to_return
}


# Changes a few things to their HTML equivalents.
proc address_book_display_as_html { text_to_display } {
    regsub -all "\\&" $text_to_display "\\&amp;" html_text
    regsub -all "\>" $html_text "\\&gt;" html_text
    regsub -all "\<" $html_text "\\&lt;" html_text
    regsub -all "\n" $html_text "<br>\n" html_text
    regsub -all "\r\n" $html_text "<br>\n" html_text
    return $html_text
}

# takes care of leap years (since Feb 28 might not exist in the given_year)
proc address_book_birthday_in_given_year { birthday birthmonth given_year } {
    if { $birthday == "29" && $birthmonth=="02" } {
	if { [leap_year_p $given_year] } {
	    return "$given_year-02-29"
	} else {
	    return "$given_year-03-01"
	}
    } else {
	return "$given_year-$birthmonth-$birthday"
    }
	
}

proc address_book_zero_if_null { input_string } {
    if { [string compare $input_string ""] == 0 } {
	return 0
    } else {
	return $input_string
    }
}

# scheduled
proc address_book_mail_reminders { } {

    ns_log Notice "address_book_mail_reminders starting"

    set dblist [ns_db gethandle [philg_server_default_pool] 2]
    set db [lindex $dblist 0]
    set db2 [lindex $dblist 1]

    set today [database_to_tcl_string $db "select sysdate from dual"]
    set this_year [database_to_tcl_string $db "select to_char(sysdate,'YYYY') from dual"]

    set selection [ns_db select $db "select a.rowid, a.user_id, a.first_names, a.last_name, a.birthmonth, a.birthday, a.days_in_advance_to_remind, a.date_last_reminded, a.days_in_advance_to_remind_2, a.date_last_reminded_2 
from address_book a, users_alertable
where a.user_id=users_alertable.user_id
and a.birthmonth is not null
and a.birthday is not null
and (a.days_in_advance_to_remind is not null or a.days_in_advance_to_remind_2 is not null)"]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	set birthday_this_year [address_book_birthday_in_given_year $birthday $birthmonth $this_year]

	if { [database_to_tcl_string $db2 "select decode(sign( trunc(sysdate) - to_date('$birthday_this_year','YYYY-MM-DD')),1,1,0) from dual"] } {
	    # then the birthday has already occurred this year
	    set next_birthday [address_book_birthday_in_given_year $birthday $birthmonth [expr $this_year + 1] ]
	} else {
	    set next_birthday $birthday_this_year
	}

	ns_log Notice "The first query: select 1 from dual where to_date('$next_birthday','YYYY-MM-DD')-sysdate <= $days_in_advance_to_remind and (to_date('$next_birthday','YYYY-MM-DD') - to_date('$date_last_reminded','YYYY-MM-DD') >= $days_in_advance_to_remind or '$date_last_reminded' is null)"

	if { ($days_in_advance_to_remind != "" && [address_book_zero_if_null [database_to_tcl_string_or_null $db2 "select 1 from dual where to_date('$next_birthday','YYYY-MM-DD')-sysdate <= $days_in_advance_to_remind and (to_date('$next_birthday','YYYY-MM-DD') - to_date('$date_last_reminded','YYYY-MM-DD') > $days_in_advance_to_remind or '$date_last_reminded' is null)"]] ) || ($days_in_advance_to_remind_2 != "" && [address_book_zero_if_null [database_to_tcl_string_or_null $db2 "select 1 from dual where to_date('$next_birthday','YYYY-MM-DD')-sysdate <= $days_in_advance_to_remind_2 and (to_date('$next_birthday','YYYY-MM-DD') - to_date('$date_last_reminded','YYYY-MM-DD') > $days_in_advance_to_remind_2 or '$date_last_reminded' is null)"]] )  } {

	    # then a reminder is due!
	
	    set user_email [database_to_tcl_string $db2 "select email from users where user_id=$user_id"]

	    set pretty_next_birthday [database_to_tcl_string $db2 "select to_char(to_date('$next_birthday','YYYY-MM-DD'),'Day, Month DD') from dual"]
	    # I don't know why Oracle pads the above with extra spaces
	    regsub -all " ( )+" $pretty_next_birthday " " pretty_next_birthday
	    regsub -all " ," $pretty_next_birthday "," pretty_next_birthday

	    set email_body "This is an automatic reminder that $first_names $last_name's birthday is on 
$pretty_next_birthday.

Here is the information you have about them in your address book:

[address_book_record_display $rowid "f"]

To update your address book, go to:
[address_book_url]    
"

        ns_sendmail $user_email [ad_system_owner] "Birthday reminder: $first_names $last_name" $email_body

        ns_db dml $db2 "update address_book set date_last_reminded=sysdate where rowid='[DoubleApos $rowid]'"
        }
    }

    ns_log Notice "address_book_mail_reminders ending"
}


ns_share -init {set address_book_procs_scheduled_p 0} address_book_procs_scheduled_p

if { !$address_book_procs_scheduled_p && [ad_parameter SendBirthdayAlerts addressbook] } {
    set address_book_procs_scheduled_p 1
    
    # scheduled to run every 12 hrs (twice a day in case one time fails)

#    ns_schedule_daily -thread 11 35 address_book_mail_reminders
    ns_schedule_daily 04 00 address_book_mail_reminders
    ns_log Notice "address_book_mail_reminders scheduled for 4:00am"

#    ns_schedule_daily -thread 23 35 address_book_mail_reminders
    ns_schedule_daily 16 00 address_book_mail_reminders
    ns_log Notice "address_book_mail_reminders scheduled for 4:00pm"

} else {
    ns_log Notice "address_book_mail_reminders not scheduled"
}


