# /tcl/address-book-defs.tcl

ad_library {
    address-book-defs.tcl
    address-book-defs.tcl,v 3.4.2.6 2000/07/31 20:16:01 kevin Exp
}

ad_proc address_book_url { } {} {
    return "/address-book/"
}

ad_proc address_book_authorized {scope {group_id 0}} "If scope=0, return 1 if the user is authorized; 0 otherwise. Otherwise, returns 1. This function will expand as we expand the permissions in the address book" {
    # user should be in the group 
    if {$scope=="group" && ![ad_user_group_member $group_id]} {
	return 0
    } else {
	return 1
    }
}

ad_proc address_book_name { } "assumes scope is set in the callers environment. if scope=group it assumes group_id is set in the callers environment, if scope=user it assumes that user_id is set in callers environment. For scope=group, returns the name of the group if the user is authorized. For scope=user, returns the person's name. For scope=public, returns the site name. For scope=table it returns an empty string."  {
    upvar scope scope 

    switch $scope {
	"public" {
	    return [ad_system_name]
	}
	"group" {
	    upvar group_id group_id
	    return [db_string address_book_select_groupname "select group_name 
            from user_groups where group_id = :group_id"]
	}
	"user" {
	    set user_id [ad_get_user_id]
	    return [db_string user_name "select first_names || ' ' || last_name from users where user_id = :user_id" -default ""]
	}
	"table" {
	    return ""
	}
    }
}

ad_proc address_book_record_display { address_book_info {contact_info_only "f"} } "Displays address in a plain text manner.  Wrap the output in address_book_display_as_html for display on web site."  {

    return [address_book_display_one_row]
}

ad_proc address_book_display_one_row { } {
    formats variables in caller's environment into a nice display for the address book. 
} {
    uplevel {
	ad_ns_set_to_tcl_vars $address_book_info

	set address_book_one_row_to_return "$first_names $last_name"
	foreach column [list $email $email2] {
	    if { [string compare $column ""] != 0 } {
		append address_book_one_row_to_return "<br><a href=\"mailto:$column\">$column</a>"
	    }

	}
	foreach column [list $line1 $line2] {
	    if { [string compare $column ""] != 0 } {
		append address_book_one_row_to_return "<br>$column"
	    }
	}
	set address_count 0
	if { [string compare $city ""] != 0 || [string compare $usps_abbrev ""] != 0 || [string compare $zip_code ""] != 0 } {
	    append address_book_one_row_to_return "<br>"
	    if { [string compare $city ""] != 0 } {
		set address_count 1
		append address_book_one_row_to_return "$city"
	    }
	    if { [string compare $usps_abbrev ""] != 0 } {
		if { $address_count == 1} {
		    append address_book_one_row_to_return ", "
		}
		append address_book_one_row_to_return "$usps_abbrev "
	    }
	    if { [string compare $zip_code ""] != 0 } {
		append address_book_one_row_to_return "$zip_code"
	    }
	}
	if { [string compare $country ""] != 0 && [string compare $country "USA"] != 0 } {
	    append address_book_one_row_to_return "<br>$country"
	}
	if { [string compare $phone_home ""] != 0 } {
	    append address_book_one_row_to_return "<br>$phone_home (home)"
	}
	if { [string compare $phone_work ""] != 0 } {
	    append address_book_one_row_to_return "<br>$phone_work (work)"
	}
	if { [string compare $phone_cell ""] != 0 } {
	    append address_book_one_row_to_return "<br>$phone_cell (cell)"
	}
	if { [string compare $phone_other ""] != 0 } {
	    append address_book_one_row_to_return "<br>$phone_other (other)"
	}
	if { [string compare $birthmonth ""] != 0 && [info exists contact_info_only] && $contact_info_only == "f" } {
	    append address_book_one_row_to_return "<br>birthday $birthmonth/$birthday"
	}
	if { [string compare $birthyear ""] != 0 && [info exists contact_info_only] && $contact_info_only == "f" } {
	    append address_book_one_row_to_return "/$birthyear"
	}
	if { [string compare $notes ""] != 0 && [info exists contact_info_only] && $contact_info_only == "f" } {
	    append address_book_one_row_to_return "<br>\[$notes\]"
	}
	
	return $address_book_one_row_to_return
    }
}

ad_proc address_book_birthday_widget { {birthmonth ""} {birthday ""} {birthyear ""} } {} {
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
ad_proc address_book_display_as_html { text_to_display } {} {
    regsub -all "\\&" $text_to_display "\\&amp;" html_text
    regsub -all "\>" $html_text "\\&gt;" html_text
    regsub -all "\<" $html_text "\\&lt;" html_text
    regsub -all "\n" $html_text "<br>\n" html_text
    regsub -all "\r\n" $html_text "<br>\n" html_text
    return $html_text
}

# takes care of leap years (since Feb 28 might not exist in the given_year)
ad_proc address_book_birthday_in_given_year { birthday birthmonth given_year } {} {
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

ad_proc address_book_zero_if_null { input_string } {} {
    if { [string compare $input_string ""] == 0 } {
	return 0
    } else {
	return $input_string
    }
}

# scheduled
ad_proc address_book_mail_reminders { } {} {

    ns_log Notice "address_book_mail_reminders starting"

    set today [db_string address_book_defs_getdate "select sysdate from dual"]
    set this_year [db_string address_book_defs_getyear "select 
    to_char(sysdate,'YYYY') from dual"]

    db_foreach address_book_defs_getdata "select a.rowid, a.user_id, a.first_names, a.last_name, a.birthmonth, a.birthday, a.days_in_advance_to_remind, a.date_last_reminded, a.days_in_advance_to_remind_2, a.date_last_reminded_2 
from address_book a, users_alertable
where a.user_id=users_alertable.user_id
and a.birthmonth is not null
and a.birthday is not null
and (a.days_in_advance_to_remind is not null or a.days_in_advance_to_remind_2 is not null)" {
	set birthday_this_year [address_book_birthday_in_given_year $birthday $birthmonth $this_year]

        if { [db_string address_book_defs_get_coded_date "select decode(sign( trunc(sysdate) - to_date(:birthday_this_year,'YYYY-MM-DD')),1,1,0) from dual"] }{
	    # then the birthday has already occurred this year
	    set next_birthday [address_book_birthday_in_given_year $birthday $birthmonth [expr $this_year + 1] ]
	} else {
	    set next_birthday $birthday_this_year
	}

	ns_log Notice "The first query: select 1 from dual where to_date('$next_birthday','YYYY-MM-DD')-sysdate <= $days_in_advance_to_remind and (to_date('$next_birthday','YYYY-MM-DD') - to_date('$date_last_reminded','YYYY-MM-DD') >= $days_in_advance_to_remind or '$date_last_reminded' is null)"

	if { ($days_in_advance_to_remind != "" && [address_book_zero_if_null [db_string address_book_defs_select1 "select 1 from dual where to_date(:next_birthday,'YYYY-MM-DD')-sysdate <= :days_in_advance_to_remind and (to_date(:next_birthday,'YYYY-MM-DD') - to_date('$date_last_reminded','YYYY-MM-DD') > :days_in_advance_to_remind or '$date_last_reminded' is null)" -default ""]] ) || ($days_in_advance_to_remind_2 != "" && [address_book_zero_if_null [db_string address_book_defs_select_1 "select 1 from dual where to_date(:next_birthday,'YYYY-MM-DD')-sysdate <= :days_in_advance_to_remind_2 and (to_date(:next_birthday,'YYYY-MM-DD') - to_date('$date_last_reminded','YYYY-MM-DD') > :days_in_advance_to_remind_2 or ':date_last_reminded' is null)"]  -default ""]) } {

	    # then a reminder is due!
            
	    set user_email [db_string address_book_defs_getemail "select email from users where user_id= :user_id"]

	    set pretty_next_birthday [db_string address_book_defs_getbday "select 
            to_char(to_date(:next_birthday,'YYYY-MM-DD'),'Day, Month DD') 
            from dual"]
	    
            # I don't know why Oracle pads the above with extra spaces
	    regsub -all " ( )+" $pretty_next_birthday " " pretty_next_birthday
	    regsub -all " ," $pretty_next_birthday "," pretty_next_birthday
            
	    set email_body "This is an automatic reminder that $first_names $last_name's birthday is on 
            $pretty_next_birthday.
            
            Here is the information you have about them in your address book:

            [address_book_record_display $rowid "f"]
            
            To update your address book, go to:
            [address_book_url]"
            
            ns_sendmail $user_email [ad_system_owner] "Birthday reminder: $first_names $last_name" $email_body
            
            db_dml address_book_defs_update_book "update address_book 
            set date_last_reminded=sysdate where rowid=:rowid"
        }
    }
    ns_log Notice "address_book_mail_reminders ending"


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
}
