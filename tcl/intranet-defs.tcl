# Name:        /tcl/intranet-defs.tcl
# Author:      Michael Bryzek <mbryzek@arsdigita.com> and a bunch of other people
# Date:        27 Feb 2000
# Description: Definitions for the intranet module

util_report_library_entry

ns_share -init {set ad_intranet_security_filters_installed 0} ad_intranet_security_filters_installed

if {!$ad_intranet_security_filters_installed} {
    set ad_intranet_security_filters_installed 1
    # we will bounce people out of /intranet if they don't have a cookie
    # and if they are not authorized users
 
    ad_register_filter preauth HEAD /intranet/* im_user_is_authorized
    ad_register_filter preauth GET /intranet/* im_user_is_authorized
    ad_register_filter preauth POST /intranet/* im_user_is_authorized

    # protect the /employees/admin directory to either site-wide administrators
    # or intranet administrators
    ad_register_filter preauth HEAD /intranet/employees/admin/* im_verify_user_is_admin
    ad_register_filter preauth GET /intranet/employees/admin/* im_verify_user_is_admin
    ad_register_filter preauth POST /intranet/employees/admin/* im_verify_user_is_admin
}

proc_doc im_user_is_employee_p { db user_id } {Returns 1 if a the user is in the employee group. 0 Otherwise} {
    return [database_to_tcl_string $db \
	    "select decode(ad_group_member_p($user_id, [im_employee_group_id]), 't', 1, 0) from dual"]
}

proc_doc im_user_is_authorized {conn args why} {Returns filter_ok if user is employee} {
    set user_id [ad_verify_and_get_user_id]
    if { $user_id == 0 } {
	# Not logged in
	ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    }
    set db [ns_db gethandle]
    set is_authorized_p [im_user_is_authorized_p $db $user_id]
    ns_db releasehandle $db 
    if { $is_authorized_p > 0 } {
	return filter_ok
    } else {
	ad_return_error "Access denied" "You must be an employee of [ad_parameter SystemName] to see this page"
	return filter_return	
    }
}


proc_doc im_user_is_customer_p { db user_id } {Returns 1 if a the user is in a customer group. 0 Otherwise} {
    return [database_to_tcl_string $db \
	    "select decode(ad_group_member_p($user_id, [im_customer_group_id]), 't', 1, 0) from dual"]
}

proc_doc im_user_is_customer {conn args why} {Returns filter_of if user is customer} {
    set user_id [ad_get_user_id]
    if { $user_id == 0 } {
	# Not logged in
	ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    }
    set db [ns_db gethandle]
    set is_customer_p [im_user_is_customer_p $db $user_id]
    ns_db releasehandle $db 
    if { $is_customer_p > 0 } {
	return filter_ok
    } else {
	ad_return_error "Access denied" "You must be a customer of [ad_parameter SystemName] to see this page"
	return filter_return	
    }
}

proc_doc im_verify_user_is_admin { conn args why } {Returns 1 if a the user is either a site-wide administrator or in the Intranet administration group} {
    set user_id [ad_get_user_id]
    if { $user_id == 0 } {
	# Not logged in
	ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    }
    set db [ns_db gethandle subquery]
    set val [im_is_user_site_wide_or_intranet_admin $db $user_id]
    ns_db releasehandle $db 
    if { $val > 0 } {
	return filter_ok
    } else {
	ad_return_error "Access denied" "You must be an administrator of [ad_parameter SystemName] to see this page"
	return filter_return	
    }
}

ns_share im_status_report_section_list

if { ![info exists im_status_report_section_list] || [lsearch -glob $im_status_report_section_list "im_num_employees"] == -1 } {
    lappend im_status_report_section_list [list "Population Count" im_num_employees]
}

if { ![info exists im_status_report_section_list] || [lsearch -glob $im_status_report_section_list "im_recent_employees"] == -1 } {
    lappend im_status_report_section_list [list "New ArsDigitans" im_recent_employees]
}

if { ![info exists im_status_report_section_list] || [lsearch -glob $im_status_report_section_list "im_future_employees"] == -1 } {
    lappend im_status_report_section_list [list "Future ArsDigitans" im_future_employees]
}

if { ![info exists im_status_report_section_list] || [lsearch -glob $im_status_report_section_list "im_vacationing_employees"] == -1 } {
    lappend im_status_report_section_list [list "ArsDigitans Out of the Office" im_vacationing_employees]
}

if { ![info exists im_status_report_section_list] || [lsearch -glob $im_status_report_section_list "im_future_vacationing_employees"] == -1 } {
    lappend im_status_report_section_list [list "Future office excursions" im_future_vacationing_employees]
}

if { ![info exists im_status_report_section_list] || [lsearch -glob $im_status_report_section_list "im_delinquent_employees"] == -1 } {
    lappend im_status_report_section_list [list "Delinquent ArsDigitans" im_delinquent_employees]
}

if { ![info exists im_status_report_section_list] || [lsearch -glob $im_status_report_section_list "im_customers_bids_out"] == -1 } {
    lappend im_status_report_section_list [list "Customers: Bids Out" im_customers_bids_out]
}

if { ![info exists im_status_report_section_list] || [lsearch -glob $im_status_report_section_list "im_customers_status_change"] == -1 } {
    lappend im_status_report_section_list [list "Customers: Status Changes" im_customers_status_change]
}

if { ![info exists im_status_report_section_list] || [lsearch -glob $im_status_report_section_list "im_user_registrations"] == -1 } {
    lappend im_status_report_section_list [list "New Registrants at [ad_parameter SystemURL]" im_new_registrants]
}


if { ![info exists im_status_report_section_list] || [lsearch -glob $im_status_report_section_list "im_customers_comments"] == -1 } {
    # lappend im_status_report_section_list [list "Customers: Correspondence" im_customers_comments]
}

if { ![info exists im_status_report_section_list] || [lsearch -glob "$im_status_report_section_list" "im_news_status" ] == -1 } {
    lappend im_status_report_section_list [list "News" im_news_status]
}

proc im_news_status {db {coverage ""} {report_date ""} {purpose ""} } {
    if { [empty_string_p $coverage] } {
	set coverage 1
    } 
    if { [empty_string_p $report_date] } {
	set report_date sysdate
    } else {
	set report_date "'$report_date'"
    }
    set since_when [database_to_tcl_string $db "select to_date($report_date, 'YYYY-MM-DD') - $coverage from dual"]
    return [news_new_stuff $db $since_when "f" $purpose]
}

if { ![info exists im_status_report_section_list] || [lsearch -glob $im_status_report_section_list "im_project_reports"] == -1 } {
    lappend im_status_report_section_list [list "Progress Reports" im_project_reports]
}

proc im_task_general_comment_section {db task_id name} {
    set spam_id [database_to_tcl_string $db "select spam_id_sequence.nextval from dual"]
    set return_url  "[im_url]/spam.tcl?return_url=[ns_conn url]?[export_ns_set_vars]&task_id=$task_id&spam_id=$spam_id"

    set html "
<em>Comments</em>
[ad_general_comments_summary $db $task_id im_tasks $name]
<P>
<center>
(<A HREF=\"/general-comments/comment-add.tcl?on_which_table=im_tasks&on_what_id=$task_id&item=[ns_urlencode $name]&module=intranet&return_url=[ns_urlencode $return_url]\">Add a comment</a>)
</center>
</UL>"

    return $html
}

proc im_removal_instructions_old {user_id} {
#generic removal instuctions with a customized url


    set message "
---------------------------- REMOVAL INSTRUCTIONS

You've gotten this spam because you're a registered user at 
[im_url]

Theoretically you signed up to be on our mailing list but it might
have been years ago and it could have been someone using your email
address without authorization.

There are a variety of ways for you to control the amount of email
that you're getting from this server.  If you want to exercise
fine-grained control, you can come back to [im_url]/mailing-list/ and
turn alerts on and off.

If you just want to apply the big hammer and stop us from ever sending
you email again, just cut and paste the following URL into your
browser:

[im_url]/mailing-list/set-dont-spam-me-p.tcl?user_id=$user_id" 
"

    return $message
}

proc im_removal_instructions {user_id} {

    set message "
------------------------------
Sent through [im_url]
"

    return $message
}

proc im_spam {db user_id_list from_address subject message spam_id {add_removal_instructions_p 0} } { 
    #Spams an user_id_list
    #Does not automatically add removal instructions
    set html ""
    set user_id [ad_get_user_id]    
    if [catch { ns_ora clob_dml $db "insert into spam_history
    (spam_id, from_address, title, body_plain, creation_date, creation_user, creation_ip_address, status)
    values
    ($spam_id, '[DoubleApos $from_address]', '[DoubleApos $subject]', empty_clob(), sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]', 'sending')
    returning body_plain into :1" $message } errmsg] {
    # choked; let's see if it is because 
	if { [database_to_tcl_string $db "select count(*) from spam_history where spam_id = $spam_id"] > 0 } {
	    set error_message "<blockquote>An error has occured and no email was sent because the database thinks this email was already sent.  Please check the project page and see if your changes have been made. </blockquote></p>"
	    return $error_message
	} else {
	    ad_return_error "Ouch!" "The database choked on your insert:
	    <blockquote>
	    $errmsg
	    </blockquote>
	    "
	}
    }
    set sent_html ""
    set failure_htlm ""
    set failure_count 0
    foreach mail_to_id $user_id_list {
	set email [database_to_tcl_string_or_null $db "
	select email 
	from users_spammable 
	where user_id = $mail_to_id" 0]
	if { $email == 0 } {
	    incr failure_count
	    #get the failure persons' name if available.
	    set failed_name [catch { [database_to_tcl_string $db "
	    select first_names || ' ' || last_name as name 
	    from users 
	    where user_id = $mail_to_id"] } "no name found" ]
	    append failure_html "<li> no email address was found for user_id = $mail_to_id: name = $failed_name"

	} else {
	    if { $add_removal_instructions_p } {
		append message [im_removal_instructions $mail_to_id]
	    }
	    ns_sendmail $email $from_address $subject $message
	    ns_db dml $db "update spam_history set n_sent = n_sent + 1 where spam_id = $spam_id"
	    append sent_html "<li>$email...\n"
	}
    }
    set n_sent [database_to_tcl_string $db "select n_sent from spam_history where spam_id = $spam_id"]
    ns_db dml $db "update spam_history set status = 'sent' where spam_id = $spam_id"
    append html "<blockquote>Email was sent $n_sent email addresses.  <p> If any of these addresses are bogus you will recieve a bounced email in your box<ul> $sent_html </ul> </blockquote>"
    if { $failure_count > 0 } {
	append html "They databased did not have email addresses or the user has requested that spam be blocked in the following $failure_count cases: 
	<ul> $failure_html </ul>"
    }
    return $html
}

proc im_name_in_mailto {db user_id} {
    if { $user_id > 0 } {
	set selection [ns_db 1row $db "select first_names || ' ' || last_name as name, email 
	from users 
	where user_id=$user_id"]
	
	set_variables_after_query
	set mail_to "<a href=mailto:$email>$name</a>"
    } else {
	set mail_to "Unassigned"
    }
    return $mail_to
}

proc im_name_paren_email {db user_id} {
    if { $user_id > 0 } {
	set selection [ns_db 1row $db "select first_names || ' ' || last_name as name, email 
	from users 
	where user_id=$user_id"]
    
	set_variables_after_query
	set text "$name: $email"
    } else {
	set text "Unassigned"
    }    
    return $text
}

proc im_db_html_select_value_options_plus_hidden {db query list_name {select_option ""} {value_index 0} {label_index 1}} {
    #this is html to be placed into a select tag
    #when value!=option, set the index of the return list
    #from the db query. selected option must match value
    #it also sends a hidden variable with all the values 
    #designed to be availavle for spamming a list of user ids from the next page.

    set select_options ""
    set values_list ""
    set options [database_to_tcl_list_list $db $query]
    foreach option $options {
	set one_label [lindex $option $label_index] 
	set one_value [lindex $option $value_index]
	if { [lsearch $select_option $one_value] != -1 } {
	    append select_options "<option value=$one_value selected>$one_label\n"
	    lappend values_list $one_value
	} else {
	    append select_options "<option value=$one_value>$one_label\n"
	    lappend values_list $one_value
	}
    }
    if { [empty_string_p $values_list] } {
	# use 0 for unassigned and/or no one is on the project
	ns_log warning "values list empty!"
	append select_options "<option value=0>unassigned\n"
    	set value_list 0
    }
    append select_options "</select> [philg_hidden_input $list_name $values_list]"
    return $select_options
}



proc value_if_exists {var_name} {
    upvar $var_name $var_name
    if [info exists $var_name] {
        return [set $var_name]
    }
}


proc im_employee_select_optionlist {db {user_id ""} } {
    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    return [db_html_select_value_options $db "select
 distinct u.user_id , u.last_name || ', ' || u.first_names as name
from users_active u, user_group_map ugm
where u.user_id = ugm.user_id
and ugm.group_id = [im_employee_group_id]
order by lower(name)" $user_id]
}


proc_doc im_num_employees {db {since_when ""} {report_date ""} {purpose ""}} "Returns string that gives # of employees and full time equivalents" {

    set num_employees [database_to_tcl_string $db \
	    "select count(time.percentage_time) 
               from im_employee_info info, im_employee_percentage_time  time
              where (time.percentage_time is not null and time.percentage_time > 0)
                and (info.start_date < sysdate)
                and time.start_block = to_date(next_day(sysdate-8, 'SUNDAY'), 'YYYY-MM-DD')
                and time.user_id=info.user_id"]

    set num_fte [database_to_tcl_string $db \
	    "select sum(time.percentage_time) / 100
               from im_employee_info info, im_employee_percentage_time  time
              where (time.percentage_time is not null and time.percentage_time > 0)
                and (info.start_date < sysdate or info.start_date is null)
                and time.start_block = to_date(next_day(sysdate-8, 'SUNDAY'), 'YYYY-MM-DD')
                and time.user_id=info.user_id"]

    if { [empty_string_p $num_fte] } {
	set num_fte 0
    }
     
    set return_string "We have $num_employees [util_decode $num_employees 1 employee employees] ($num_fte full-time [util_decode $num_fte 1 $num_fte equivalent equivalents])"

    if {$purpose == "web_display"} {
	return "<blockquote>$return_string</blockquote>"
    } else {
	return "$return_string"
    }
}

proc_doc im_num_employees_simple { { db "" } } "Returns # of employees." {
    if { [empty_string_p $db] } {
	set db [ns_db gethandle subquery]
	set release 1
    } else {
	set release 0
    }
    set num_employees [database_to_tcl_string $db \
	    "select count(time.percentage_time) 
               from im_employee_info info, im_employee_percentage_time  time
              where (time.percentage_time is not null and time.percentage_time > 0)
                and (info.start_date < sysdate)
                and time.start_block = to_date(next_day(sysdate-8, 'SUNDAY'), 'YYYY-MM-DD')
                and time.user_id=info.user_id"]

    if { $release } {
	ns_db releasehandle $db
    }
    return $num_employees
}


proc_doc im_num_offices_simple { { db "" } } "Returns # of offices." {
    if { [empty_string_p $db] } {
	set db [ns_db gethandle subquery]
	set release 1
    } else {
	set release 0
    }
    set num_offices [database_to_tcl_string $db \
	    "select count(1) 
               from user_groups
              where parent_group_id = [im_office_group_id]"]
    if { $release } {
	ns_db releasehandle $db
    }
    return $num_offices
}


proc_doc im_recent_employees {db {coverage ""} {report_date ""} {purpose ""}} "Retuns a string that gives a list of recent employees" {

    if { [empty_string_p $coverage] } {
	set coverage 1
    }
    if { [empty_string_p $report_date] } {
	set report_date sysdate
    } else {
	set report_date "'$report_date'"
    }
	

    set selection [ns_db select $db "select u.first_names, u.last_name, u.email, info.start_date, u.user_id
from users_active u, im_employee_info info
where u.user_id =info.user_id
and info.start_date < sysdate
and info.start_date + $coverage > $report_date
order by start_date"]
    set return_list [list]
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if {$purpose == "web_display"} {
	    lappend return_list "<a href=[im_url_stub]/users/view.tcl?[export_url_vars user_id]>$first_names $last_name</a> ($email) - [util_IllustraDatetoPrettyDate $start_date]"
	} else {
	    lappend return_list "$first_names $last_name ($email) - [util_IllustraDatetoPrettyDate $start_date], "
	}
    }
    
    if {[llength $return_list] == 0} {
	return "None \n"
    }

    if {$purpose == "web_display"} {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "[join $return_list ", "] "
    }

}

proc_doc im_future_employees {db {coverage ""} {report_date ""} {purpose ""}} "Returns a string that gives a list of future employees" {

    set selection [ns_db select $db "select u.user_id, first_names, last_name, email, start_date, job_title, 
decode(im_employee_percentage_time.percentage_time, NULL, '', im_employee_percentage_time.percentage_time||'% ') as percentage_string
from users_active u, im_employee_info info, im_employee_percentage_time
where u.user_id =info.user_id
and im_employee_percentage_time.user_id = info.user_id
and 
  (im_employee_percentage_time.start_block = (select min(start_block) from
im_employee_percentage_time 
where im_employee_percentage_time.user_id = info.user_id) 
or im_employee_percentage_time.start_block is null)
and info.start_date > '$report_date'
order by start_date"]
    set return_list [list]
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	if {$purpose == "web_display"} {
	    lappend return_list "$percentage_string $job_title: <a href=[im_url_stub]/users/view.tcl?[export_url_vars user_id]>$first_names $last_name</a> - ($email)  [util_IllustraDatetoPrettyDate $start_date]"
	} else {
	    lappend return_list "$percentage_string $job_title: $first_names $last_name  [util_IllustraDatetoPrettyDate $start_date]"
	}


    }

    if {[llength $return_list] == 0} {
	return "None \n"
    }
    
    if {$purpose == "web_display"} {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "[join $return_list "\n"]"
    }

}



proc_doc im_vacationing_employees {db {coverage ""} {report_date ""} {purpose ""}} "Returns a string that gives a list of vacationing employees" {

    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    set selection [ns_db select $db "select
 distinct u.user_id, u.first_names, u.last_name, u.email, 
to_char(user_vacations.start_date,'Mon DD, YYYY') || ' - ' || to_char(user_vacations.end_date,'Mon DD, YYYY') as dates, user_vacations.end_date
from users_active u, user_vacations , user_group_map ugm
where u.user_id = ugm.user_id
and ugm.group_id = [im_employee_group_id]
and u.user_id = user_vacations.user_id 
and user_vacations.start_date < to_date('$report_date', 'YYYY-MM-DD')
and user_vacations.end_date > to_date('$report_date', 'YYYY-MM-DD')
order by user_vacations.end_date
"]
    set return_list [list]
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	if {$purpose == "web_display"} {
	    lappend return_list "<a href=[im_url_stub]/users/view.tcl?[export_url_vars user_id]>$first_names $last_name</a> - $dates"
	} else {
	    lappend return_list "$first_names $last_name - $dates"
	}
    }

    if {[llength $return_list] == 0} {
	return "None \n"
    }
    
    if {$purpose == "web_display"} {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "[join $return_list "\n"] "
    }

}

proc_doc im_customers_comments {db {coverage ""} { report_date ""} {purpose ""}} "Returns a string that gives a list  of customer profiles that have had correspondences - comments - addedto them with in the period of the coverage date from the report date" {

    if { [empty_string_p $report_date] } {
	set report_date [database_to_tcl_string $db "select sysdate from dual"] 
    }

    set selection [ns_db select $db \
	    "select u.user_id, first_names, last_name, 
                    general_comments.content, general_comments.html_p, user_groups.group_name,
                    im_projects.project_id, comment_date, one_line, comment_id
               from users_active u, general_comments, im_projects, user_groups
              where u.user_id =general_comments.user_id
                and im_projects.project_id = general_comments.on_what_id
                and on_which_table = 'im_customers'
                and comment_date > to_date('$report_date', 'YYYY-MM-DD') - $coverage
                and user_groups.group_id=im_projects.group_id
              order by lower(group_name), comment_date"]

    set return_list [list]
    set return_url "[im_url]/customers/view.tcl?[export_url_vars group_id]"
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	
	if {$purpose == "web_display"} {
	    lappend return_list "<a href=/general-comments/view-one.tcl?[export_url_vars comment_id]&item=[ns_urlencode $group_name]&[export_url_vars return_url]>$one_line</a> -  <a href=[im_url_stub]/project-info.tcl?[export_url_vars project_id]>$name</a> by <a href=[im_url_stub]/users/view.tcl?[export_url_vars user_id]>$first_names $last_name</a> on [util_IllustraDatetoPrettyDate $comment_date]<br>
	    
	    [util_maybe_convert_to_html $content $html_p]
	    "
	} else {
    
	    lappend return_list "$one_line - $name by $first_names $last_name on [util_IllustraDatetoPrettyDate $comment_date]
	    \n
	    [util_striphtml $content]
	    
	    -- [im_url]/project-info.tcl?[export_url_vars project_id]
	    "
	}
    }

    set end_date [database_to_tcl_string $db "select sysdate-$coverage from dual"]
    
    if {[llength $return_list] == 0} {
	return "No customer correspondences in period [util_IllustraDatetoPrettyDate $end_date] -  [util_IllustraDatetoPrettyDate $report_date].\n"
    }
    
    if {$purpose == "web_display"} {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "\n [join $return_list "\n"] "
    }
}

proc_doc im_new_registrants {db {coverage ""} {report_date ""} {purpose ""}} {Returns the number of people who've registered over a period of time} {
    set selection [ns_db 1row $db \
	    "select count(1) as num_users, sysdate-[util_decode $coverage "" 1 $coverage] as end_date, sysdate as todays_date
               from users 
    	      where registration_date > to_date([util_decode $report_date "" sysdate "'$report_date'"], 'YYYY-MM-DD')-[util_decode $coverage "" 1 $coverage]"]
    
    set_variables_after_query

    if { [empty_string_p $report_date] } {
	set report_date $todays_date
    }
    
    return "[util_decode $num_users 0 "No new registrants" 1 "1 new registrant" "$num_users new registrants"] in period [util_IllustraDatetoPrettyDate $end_date] -  [util_IllustraDatetoPrettyDate $report_date].\n"
}





proc_doc im_customers_status_change {db {coverage ""} {report_date ""} {purpose ""}} "Returns a string that gives a list of customers that have had a status change with in the coverage date from the report date.  It also displays what status change they have undergone.  Note that the most recent status change is listed for the given period." {
    
    set selection [ns_db select $db \
	"select g.group_name, g.group_id, to_char(status_modification_date, 'Mon DD, YYYY') as status_modification_date,
                im_cust_status_from_id(customer_status_id) as status,
                im_cust_status_from_id(old_customer_status_id) as old_status
	   from im_customers c, user_groups g
	  where status_modification_date > to_date([util_decode $report_date "" sysdate "'$report_date'"], 'YYYY-MM-DD')-[util_decode $coverage "" 1 $coverage]
            and old_customer_status_id is not null
	    and old_customer_status_id <> customer_status_id
	    and c.group_id=g.group_id
	  order by lower(group_name)"]
	  
    set return_list [list]
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if {$purpose == "web_display"} {
	lappend return_list "<a href=[im_url_stub]/customers/view.tcl?[export_url_vars group_id]>$group_name</a> went from <b>$old_status</b> to <b>$status</b> on $status_modification_date." 
	} else {
	    lappend return_list "$group_name went from $old_status to $status on $status_modification_date."
	}
    }

    if {[llength $return_list] == 0} {
	set end_date [database_to_tcl_string $db "select sysdate-[util_decode $coverage "" 1 $coverage] from dual"]
	if { [empty_string_p $report_date] } {
	    set report_date [database_to_tcl_string $db "select sysdate from dual"]
	}
	return "No status changes in period [util_IllustraDatetoPrettyDate $end_date] -  [util_IllustraDatetoPrettyDate $report_date].\n"
    }
    
    if {$purpose == "web_display"} {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "\n[join $return_list "\n"] "
    }    
}

proc_doc im_customers_bids_out {db {coverage ""} {report_date ""} {purpose ""}} "Returns a string that gives a list of bids given out to customers" {

    set selection [ns_db select $db \
	"select g.group_id, g.group_name, to_char(c.status_modification_date, 'Mon DD, YYYY') as bid_out_date,
                u.first_names||' '||u.last_name as contact_name, u.email,
                decode(uc.work_phone,null,uc.home_phone,uc.work_phone) as contact_phone
	   from user_groups g, im_customers c, users_active u, users_contact uc
	  where g.parent_group_id=[im_customer_group_id]
	    and g.group_id=c.group_id
            and c.primary_contact_id=u.user_id(+)
            and c.primary_contact_id=uc.user_id(+)
            and c.customer_status_id=(select customer_status_id 
                                        from im_customer_status
                                       where upper(customer_status) = 'BID OUT')
          order by lower(group_name)"]

    set return_list [list]
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if {$purpose == "web_display"} {
	    lappend return_list "<a href=[im_url_stub]/customers/view.tcl?[export_url_vars group_id]>$group_name</a>, $bid_out_date[util_decode $contact_name  " " "" ", $contact_name"][util_decode $email "" "" ", <a href=mailto:$email>$email</a>"][util_decode $contact_phone "" "" ", $contact_phone"]"
	} else {
	    lappend return_list "$group_name, $bid_out_date[util_decode $contact_name " " "" ", $contact_name"][util_decode $email "" "" ", $email"][util_decode $contact_phone "" "" ", $contact_phone"]\n"
	}
    }
    
    if {[llength $return_list] == 0} {
	return "No bids out. \n"
    }
    
    if {$purpose == "web_display"} {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "\n[join $return_list "\n"] "
    }
}

proc_doc im_future_vacationing_employees {db {coverage ""} {report_date ""} {purpose ""}} "Returns a string that gives a list of recent employees" {

    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    set selection [ns_db select $db "select
 distinct u.user_id, first_names, last_name, email, 
to_char(user_vacations.start_date,'Mon DD, YYYY') || ' - ' || to_char(user_vacations.end_date,'Mon DD, YYYY') as dates, user_vacations.end_date
from users_active u, user_vacations , user_group_map ugm
where u.user_id = ugm.user_id
and ugm.group_id = [im_employee_group_id]
and u.user_id = user_vacations.user_id 
and user_vacations.start_date > to_date('$report_date', 'YYYY-MM-DD')
and user_vacations.start_date < to_date('$report_date', 'YYYY-MM-DD') + 30
order by user_vacations.end_date"]

    set return_list [list]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	if {$purpose == "web_display"} {
	    lappend return_list "<a href=[im_url_stub]/users/view.tcl?[export_url_vars user_id]>$first_names $last_name</a>- $dates"
	} else {
	    lappend return_list "$first_names $last_name - $dates"
	}
    }

    if {[llength $return_list] == 0} {
	return "None \n"
    }
    
    if {$purpose == "web_display"} {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "\n[join $return_list "\n"] "
    }

}



proc_doc im_delinquent_employees {db {coverage ""} {report_date ""} {purpose ""}} "Returns a string that gives a list of recent employees" {

#     set user_class_selection [ns_set create selection]

#     # We are forced to hard code the number because the user_class
#     # table doesn't have a non-integer key. This is not good.
#     # 57
#     set user_class_id [ad_parameter UserClassStatusReportID intranet]
#     if { [empty_string_p $user_class_id] } {
# 	return ""
#     }
#     ns_set put $user_class_selection user_class_id $user_class_id
#     set user_class_sql_query [ad_user_class_query $user_class_selection]

#    set selection [ns_db select $db $user_class_sql_query]

    set selection [ns_db select $db \
	    "select u.user_id, u.first_names || ' ' || u.last_name as name
                 from (select distinct users_active.user_id, 
                       users_active.first_names, users_active.last_name
                       from users_active, user_group_map
                       where users_active.user_id = user_group_map.user_id
                       and user_group_map.group_id = [im_employee_group_id]) u, 
              im_employee_info info
              where u.user_id = info.user_id
                and sysdate > info.start_date
                and exists (select 1 
                                from im_employee_percentage_time
                                 where im_employee_percentage_time.user_id=u.user_id
                                 and start_block between to_date('$report_date')-7 
                                  and to_date('$report_date')
                                  and im_employee_percentage_time.percentage_time > 0)
                and not exists (select 1 
                                  from im_hours h
                                 where h.user_id=u.user_id
                                   and h.day between to_date('$report_date')-7 and to_date('$report_date'))"]

    set count 0
    set return_string [list]
    set return_list ""
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	if {$purpose == "web_display"} {
	    lappend return_list "<a href=[im_url_stub]/users/view.tcl?[export_url_vars user_id]>$name</a>"
	} else {
	    lappend return_list $name
	}
    }
    
    if {[llength $return_list] > 0} {
	if {$purpose == "web_display"} {
	    append return_string "<blockquote>The following ArsDigitans have not logged their work in over 7 days: <br>
[join $return_list " | "]
</blockquote>"
        }  else {
	    append return_string "The following ArsDigitans have not logged their work in over 7 days: 
[join $return_list " | "]"
	}
    }

    set return_list [list]

    set selection [ns_db select $db \
	    "select u.first_names || ' ' || u.last_name as name, u.user_id,
                    g.group_id, g.group_name
               from im_projects p, user_groups g, users_active u
              where p.parent_id is null 
                and p.group_id = g.group_id
                and p.project_lead_id = u.user_id
                and exists (select 1 from user_group_map where group_id=[im_employee_group_id] and user_id=u.user_id)
                and p.project_status_id = (select project_status_id 
                                             from im_project_status
                                            where project_status='Open')
                and p.group_id not in (select on_what_id from general_comments 
                                        where on_which_table = 'im_projects'
                                          and comment_date between to_date('$report_date')-7 and to_date('$report_date')+1)
              order by lower(g.group_name)"]
    # note: report_date + 1 about is to catch the case
    # where the user submitted it on that day
    
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	if {$purpose == "web_display"} {
	    lappend return_list "<a href=[im_url_stub]/users/view.tcl?[export_url_vars user_id]>$name</a> on <a href=[im_url_stub]/projects/view.tcl?[export_url_vars group_id]>$group_name</a>"
	} else {
	    lappend return_list "$name on $group_name"
	}
    }

    if {[llength $return_list] > 0} {
	
	if {$purpose == "web_display"} {
	    append return_string "
<p>
<blockquote>
The following ArsDigitans are late with a progress report:
<br>
[join $return_list " | "]
</blockquote>"
	} else {
	    append return_string "
\n\n
The following ArsDigitans are late with a progress report:
[join $return_list " | "]"
	}
    
	return $return_string
    }
}




proc_doc im_project_reports {db {coverage ""} {report_date ""} {purpose ""}} "Returns a string that gives a list of recent employees" {

    if { [empty_string_p $coverage] } {
	set coverage 1
    } 
    if { [empty_string_p $report_date] } {
	set report_date sysdate
    } else {
	set report_date "'$report_date'"
    }
    set selection [ns_db select $db \
	    "select u.user_id, first_names, last_name, general_comments.content, general_comments.html_p, one_line, comment_id,
                    user_groups.group_name, user_groups.group_id, to_char(comment_date,'Mon DD, YYYY') as pretty_comment_date
              from users_active u, general_comments, user_groups, im_projects
             where u.user_id =general_comments.user_id
               and im_projects.group_id = user_groups.group_id
               and user_groups.group_id = general_comments.on_what_id
               and on_which_table = 'im_projects'
               and comment_date > to_date($report_date, 'YYYY-MM-DD') - $coverage
             order by lower(group_name), comment_date"]

    set return_list [list]
    set return_url "[im_url]/projects/view.tcl?[export_url_vars group_id]"
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	if {$purpose == "web_display"} {
	    lappend return_list "<a href=/general-comments/view-one.tcl?[export_url_vars comment_id return_url]&item=[ns_urlencode $group_name]>$one_line</a> -  <a href=[im_url_stub]/projects/view.tcl?[export_url_vars group_id]>$group_name</a> by <a href=[im_url_stub]/users/view.tcl?[export_url_vars user_id]>$first_names $last_name</a> on $pretty_comment_date

<blockquote>[util_maybe_convert_to_html $content $html_p]</blockquote>
"
	} else {

	    lappend return_list "$one_line - $group_name by $first_names $last_name on $pretty_comment_date

[util_striphtml $content]

  -- [im_url]/projects/view.tcl?[export_url_vars group_id]
"
	}


    }

    if {[llength $return_list] == 0} {
	return "None. \n"
    }
    
    if {$purpose == "web_display"} {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "\n [join $return_list "\n"] "
    }

}


proc_doc im_allocation_date_optionlist {db {start_block ""}} "Returns an optionlist of valid allocation start dates" { 
    return [ad_db_optionlist $db "select to_char(start_block,'Month DD, YYYY'), start_block from im_start_blocks order by start_block asc" $start_block]
}



proc_doc im_late_project_reports {db user_id {html_p "t"} { number_days 7 } } "Returns either a text or html block describing late project reports" {
    set return_string ""

    set selection [ns_db select $db \
	    "select g.group_name, g.group_id
               from user_groups g, im_projects p, users_active u
              where p.project_lead_id = u.user_id
                and u.user_id=$user_id
                and p.parent_id is null
                and p.group_id=g.group_id
                and p.project_status_id in (select project_status_id 
                                              from im_project_status 
                                             where project_status='Open')
                and p.group_id not in (select on_what_id from general_comments 
                                        where comment_date > sysdate - $number_days
                                          and on_which_table = 'im_projects')"]

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if {$html_p == "t"} {
	    append return_string "<li><b>Late project report:</b> <a href=[im_url_stub]/projects/report-add.tcl?[export_url_vars group_id]>$group_name</a>"
	} else {
	    append return_string "$group_name: 
  [im_url]/projects/report-add.tcl?[export_url_vars group_id]

"
	}
	
    }
    return $return_string
}



proc_doc im_slider { field_name pairs } {Takes in the name of the field in the current menu bar and a list where the ith item is the name of the form element and the i+1st element is the actual text to display. Returns an html string of the properly formatted slider bar} {
    set default [ad_partner_upvar $field_name 1]
    set url [ns_conn url]
    set query_args [export_ns_set_vars url $field_name]
    if { [empty_string_p $query_args] } {
	append url "?"
    } else {
	append url "?$query_args&"
    }
    set menu_items [list]
    for { set i 0 } { $i < [llength $pairs] } { set i [expr $i + 2] } {
	set value [lindex $pairs $i]
	set text [lindex $pairs [expr $i + 1]]
	if { [string compare $value $default] == 0 } {
	    lappend menu_items "<b>$text</b>\n"
	} else {
	    lappend menu_items "<a href=\"$url$field_name=[ns_urlencode $value]\">$text</a>\n"
	}
    }
    return [join $menu_items " | "]
}


proc_doc im_format_number { num {tag "<font size=\"+1\" color=\"blue\">"} } {Pads the specified number with the specified tag} {
    regsub {\.$} $num "" num
    return "$tag${num}.</font>"
}


proc_doc im_verify_form_variables required_vars {The standard way to verify arguments. Takes a list of pairs where the first element of the pair is the variable name and the second element of the pair is the message to display when the variable isn't defined.} {
    set err_str ""
    foreach pair $required_vars {
	if { [catch { 
	    upvar [lindex $pair 0] value
	    if { [empty_string_p $value] } {
		append err_str "  <li> [lindex $pair 1]\n"
	    } 
	} err_msg] } {
	    # This means the variable is not defined - the upvar failed
	    append err_str "  <li> [lindex $pair 1]\n"
	} 
    }	
    return $err_str
}

proc_doc im_customer_select { db select_name { default "" } { status "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the customers in the system. If status is specified, we limit the select box to customers that match that status.} {
    set sql "select ug.group_name, ug.group_id
             from user_groups ug, im_customers c
             where ug.parent_group_id=[im_customer_group_id]
               and ug.group_id = c.group_id(+)"
    if { ![empty_string_p $status] } {
	append sql " and customer_status_id=(select customer_status_id from im_customer_status where customer_status='[DoubleApos $status]')"
    }
    append sql " order by lower(group_name)"
    return [im_selection_to_select_box $db $sql $select_name $default]
}

proc_doc im_partner_status_select { db select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the partner statuses in the system} {
    set sql "select partner_status, partner_status_id
             from im_partner_status
             order by display_order, lower(partner_status)"
    return [im_selection_to_select_box $db $sql $select_name $default]
}

proc_doc im_partner_type_select { db select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the project_types in the system} {
    set sql "select partner_type, partner_type_id
             from im_partner_types
             order by display_order, lower(partner_type)"
    return [im_selection_to_select_box $db $sql $select_name $default]
}


proc_doc im_project_type_select { db select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the project_types in the system} {
    set sql "select project_type, project_type_id
             from im_project_types
             order by display_order, lower(project_type)"
    return [im_selection_to_select_box $db $sql $select_name $default]
}

proc_doc im_project_status_select { db select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the project_types in the system} {
    set sql "select project_status, project_status_id
             from im_project_status
             order by display_order, lower(project_status)"
    return [im_selection_to_select_box $db $sql $select_name $default]
}

proc_doc im_project_parent_select { db select_name { default "" } {current_group_id ""} { status "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the eligible projects for parents} {
    if { [empty_string_p $current_group_id] } {
	set limit_group_sql ""
    } else {
	set limit_group_sql " and p.group_id != $current_group_id"
    }
    set status_sql ""
    if { ![empty_string_p $status] } {
	set status_sql "and p.project_status_id=(select project_status_id from im_project_status where project_status='[DoubleApos $status]')"
    }
    set sql "select group_name, g.group_id
               from user_groups g, im_projects p 
              where p.parent_id is null 
                and g.group_id=p.group_id(+) $limit_group_sql $status_sql
              order by lower(g.group_name)"
    return [im_selection_to_select_box $db $sql $select_name $default]
}

proc_doc im_selection_to_select_box { db sql select_name { default "" } } {Expects selection to have a column named id and another named name. Runs through the selection and return a select bar named select_name, defaulted to $default } {
    return "
<select name=\"$select_name\">
<option value=\"\"> -- Please select --
[ad_db_optionlist $db $sql $default]
</select>
"
}


proc_doc im_user_select { db select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the available project_leads in the system} {

    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    set sql "select distinct u.last_name || ', ' || u.first_names, u.user_id, u.last_name, u.first_names
from users_active u, user_group_map ugm
where u.user_id = ugm.user_id
and ugm.group_id = [im_employee_group_id]
order by lower(u.last_name), lower(u.first_names)"
    return [im_selection_to_select_box $db $sql $select_name $default]
}


proc_doc im_group_id_from_parameter { parameter } {Returns the group_id for the group with the GroupShortName specified in the server .ini file for $parameter. That is, we look up the specified parameter in the intranet module of the parameters file, and use that short_name to find a group id. Memoizes the result} {
    set short_name [ad_parameter $parameter intranet]
    if { [empty_string_p $short_name] } {
	uplevel {
	    ad_return_error "Missing parameter" "Parameter not defined in the intranet section of your server's parameters file"
	    return -code return
	}
    }

    return [util_memoize "im_group_id_from_parameter_helper $short_name"]
}

proc_doc im_group_id_from_parameter_helper { short_name } {Returns the group_id for the user_group with the specified $short_name. If no such group exists, returns the empty string.} {
    set db [ns_db gethandle subquery]
    set group_id [database_to_tcl_string_or_null $db \
	    "select group_id 
               from user_groups 
              where short_name='[DoubleApos $short_name]'"]
    ns_db releasehandle $db
    return $group_id
}


proc_doc im_maybe_prepend_http { query_url } {Prepends http to query_url unless it already starts with http://} {
    set query_url [string tolower [string trim $query_url]]
    if { [empty_string_p $query_url] || [string compare $query_url "http://"] == 0 } {
	return ""
    }
    if { [regexp {^http://.+} $query_url] } {
	return $query_url
    }
    return "http://$query_url"
}

proc_doc im_table_with_title { title body } {Returns a two row table with background colors} {
    return "
<table width=100% cellpadding=2 cellspacing=2 border=0>
  <tr bgcolor=\"[ad_parameter TableColorHeader intranet white]\">
    <td><b>[ad_partner_default_font "size=-1"]$title</font></b></td>
  </tr>
  <tr bgcolor=\"[ad_parameter TableColorOdd intranet white]\">
    <td>[ad_partner_default_font "size=-1"]$body</font></td>
  </tr>
</table>
"
}


proc_doc im_customer_status_select { db select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the customer status_types in the system} {
    set sql "select customer_status, customer_status_id
             from im_customer_status
             order by display_order, lower(customer_status)"
    return [im_selection_to_select_box $db $sql $select_name $default]
}


proc_doc im_users_in_group { db group_id current_user_id { description "" } { add_admin_links 0 } { return_url "" } { limit_to_users_in_group_id "" } { dont_allow_users_in_group_id "" } { link_type "" } } {Returns an html formatted list of all the users in the specified group. Includes links to add people, add/remove yourself, and spam (if add_admin_links is 1). If limit_to_users_in_group_id is set, we only display users in both group_id and the specified group_id (in limit_to_users_in_group_id)} {
    set html ""
    if { [empty_string_p $limit_to_users_in_group_id] } {
	set limit_to_group_id_sql ""
    } else {
	set limit_to_group_id_sql "and exists (select 1 
                                                 from user_group_map map2, user_groups ug
                                                where map2.group_id = ug.group_id
                                                  and map2.user_id = users.user_id 
                                                  and (map2.group_id = $limit_to_users_in_group_id 
                                                       or ug.parent_group_id = $limit_to_users_in_group_id))"
    } 
    if { [empty_string_p $dont_allow_users_in_group_id] } {
	set dont_allow_sql ""
    } else {
	set dont_allow_sql "and not exists (select 1 
                                              from user_group_map map2, user_groups ug
                                             where map2.group_id = ug.group_id
                                               and map2.user_id = users.user_id 
                                               and (map2.group_id = $dont_allow_users_in_group_id 
                                                    or ug.parent_group_id = $dont_allow_users_in_group_id))"
    } 

    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    set sql_post_select "from users, user_group_map map
where map.user_id = users.user_id
and map.group_id = $group_id
$limit_to_group_id_sql $dont_allow_sql
order by lower(users.last_name)"

    set sql_query "select distinct
 users.user_id, users.email, users.first_names || ' ' || users.last_name as name, users.last_name
$sql_post_select"
                     
    set selection [ns_db select $db $sql_query]

    set found 0
    set count 0
    while { [ns_db getrow $db $selection] } {
	incr count
	set_variables_after_query
	if { $current_user_id == $user_id } {
	    set found 1
	}
	if { $link_type == "email_only" } {
	    append html "  <li><a href=\"mailto:$email\">$name</a>\n"
	} else {
	    append html "  <li><a href=../users/view.tcl?[export_url_vars user_id]>$name</a>"
	}
	if { $add_admin_links } {
	    append html " (<a href=/groups/member-remove-2.tcl?[export_url_vars user_id group_id return_url]>remove</a>)"
	}
	append html "\n"
    }
    
    if { [empty_string_p $html] } {
	set html "  <li><i>none</i>\n"
    }

    if { $add_admin_links } {
	if { $current_user_id > 0 } {
	    append html "  <p><a href=/groups/member-add.tcl?role=member&[export_url_vars group_id return_url limit_to_users_in_group_id]>Add a person</a>"
	    if { $found } {
		append html "  <br><a href=/groups/member-remove-2.tcl?[export_url_vars group_id return_url limit_to_users_in_group_id]&user_id=$current_user_id>Remove yourself</a>"
	    } else {
		# We might not want to offer this user the chance to add him/herself (based on the 
		# group_id set by limit_to_users_in_group_id
		if { [empty_string_p $dont_allow_users_in_group_id] } {
		    set offer_link 1
		} else {
		    set offer_link [database_to_tcl_string $db \
			    "select decode(decode(count(1),0,0,1),1,0,1)
                               from user_group_map ugm, user_groups ug
                              where ugm.group_id = ug.group_id
                                and ugm.user_id=$current_user_id
                                and (ugm.group_id=$dont_allow_users_in_group_id 
                                     or ug.parent_group_id=$dont_allow_users_in_group_id)"]
		}
		if { $offer_link } {
		    append html "  <br><a href=/groups/member-add-3.tcl?[export_url_vars group_id return_url limit_to_users_in_group_id]&user_id_from_search=$current_user_id&role=administrator>Add yourself</a>"
		}
	    }
	    if { $count > 0 } {
		# set sql_post_select [im_reduce_spaces $sql_post_select]
		set group_id_list "${group_id},$limit_to_users_in_group_id"
		append html "  <br><a href=/intranet/spam/index.tcl?[export_url_vars group_id_list description return_url]>Spam people</a>"
	    }
	}
    }
    return $html
}


proc_doc im_format_address { street_1 street_2 city state zip } {Generates a two line address with appropriate punctuation. } {
    set items [list]
    set street ""
    if { ![empty_string_p $street_1] } {
	append street $street_1
    }
    if { ![empty_string_p $street_2] } {
	if { ![empty_string_p $street] } {
	    append street "<br>\n"
	}
	append street $street_2
    }
    if { ![empty_string_p $street] } {
	lappend items $street
    }	
    set line_2 ""
    if { ![empty_string_p $state] } {
	set line_2 $state
    }	
    if { ![empty_string_p $zip] } {
	append line_2 " $zip"
    }	
    if { ![empty_string_p $city] } {
	if { [empty_string_p $line_2] } {
	    set line_2 $city
	} else { 
	    set line_2 "$city, $line_2"
	}
    }
    if { ![empty_string_p $line_2] } {
	lappend items $line_2
    }

    if { [llength $items] == 0 } {
	return ""
    } elseif { [llength $items] == 1 } {
	set value [lindex $items 0]
    } else {
	set value [join $items "<br>"]
    }
    return $value
}

proc_doc im_can_user_administer_group { db { group_id "" } { user_id ""} } {An intranet user can administer a given group if thery are a site-wide intranet user, a general site-wide administrator, or if they belong to the specified user group} {
    if { [empty_string_p $user_id] } {
	set user_id [ad_get_user_id]
    }
    if { $user_id == 0 } {
	return 0
    }
    set site_wide_or_intranet_user [im_is_user_site_wide_or_intranet_admin $db $user_id] 
    
    if { $site_wide_or_intranet_user } {
	return 1
    }

    # Else, if the user is in the group with any role, s/he can administer that group
    return [database_to_tcl_string $db \
	    "select decode(ad_group_member_p($user_id, $group_id), 't', 1, 0) from dual"]


}

proc_doc im_is_user_site_wide_or_intranet_admin { db { user_id "" } } { Returns 1 if a user is a site-wide administrator or a member of the intranet administrative group } {
    if { [empty_string_p $user_id] } {
	set user_id [ad_get_user_id]
    }
    if { $user_id == 0 } {
	return 0
    }
    if { [ad_administration_group_member $db [ad_parameter IntranetGroupType intranet] "" $user_id] } {
	# Site-Wide Intranet Administrator
	return 1
    } elseif { [ad_permission_p $db site_wide] } {
	# Site-Wide Administrator
	return 1
    } 
    return 0
}


proc_doc im_user_is_authorized_p { db user_id } {Returns 1 if a the user is authorized for the system. 0 Otherwise} {
    set authorized_p [database_to_tcl_string $db \
	    "select decode(count(1),0,0,1) 
               from user_group_map 
              where user_id=$user_id 
                and (group_id=[im_employee_group_id]
                     or group_id=[im_authorized_users_group_id])"]
    if { $authorized_p == 0 } {
	set authorized_p [im_is_user_site_wide_or_intranet_admin $db $user_id]
    }
    return $authorized_p 
}


proc_doc im_project_group_id {} {Returns the groud_id for projects} {
    return [im_group_id_from_parameter ProjectGroupShortName]
}

proc_doc im_employee_group_id {} {Returns the groud_id for employees} {
    return [im_group_id_from_parameter EmployeeGroupShortName]
}

proc_doc im_customer_group_id {} {Returns the groud_id for customers} {
    return [im_group_id_from_parameter CustomerGroupShortName]
}

proc_doc im_partner_group_id {} {Returns the groud_id for partners} {
    return [im_group_id_from_parameter PartnerGroupShortName]
}

proc_doc im_office_group_id {} {Returns the groud_id for offices} {
    return [im_group_id_from_parameter OfficeGroupShortName]
}

proc_doc im_authorized_users_group_id {} {Returns the groud_id for offices} {
    return [im_group_id_from_parameter AuthorizedUsersGroupShortName]

}

ad_proc im_burn_rate_blurb { {-db "" } } {Counts the number of employees with payroll information and returns "The company has $num_employees employees and a monthly payroll of $payroll"} {
    set release_db 0
    if { [empty_string_p $db] } {
	set release_db 1
	set db [ns_db gethandle subquery]
    }

    # We use "exists" instead of a join because there can be more
    # than one mapping between a user and a group, one for each role,
    #
    set selection [ns_db 1row $db "select count(u.user_id) as num_employees, 
ltrim(to_char(sum(salary),'999G999G999G999')) as payroll,
sum(decode(salary,NULL,1,0)) as num_missing
from im_monthly_salaries salaries, users u
where exists (select 1
              from user_group_map ugm
              where ugm.user_id = u.user_id
              and ugm.group_id = [im_employee_group_id])
and u.user_id = salaries.user_id (+)"]

    set_variables_after_query

    if { $release_db } {
	ns_db releasehandle $db
    }

    if { $num_employees == 0 } {
	return ""
    }
    set html "The company has $num_employees [util_decode $num_employees 1 employee employees]"
    if { ![empty_string_p $payroll] } {
        append html " and a monthly payroll of \$$payroll"
    }
    if { $num_missing > 0 } {
	append html " ($num_missing missing info)"
    }
    append html "."
    return $html
}


proc im_salary_period_input {} {
    return [ad_parameter SalaryPeriodInput intranet]
}

proc im_salary_period_display {} {
    return [ad_parameter SalaryPeriodDisplay intranet]
}


proc_doc im_display_salary {salary salary_period} {Formats salary for nice display} {

    set display_pref [im_salary_period_display]

    switch $salary_period {
        month {
	    if {$display_pref == "month"} {
                 return "[format %6.2f $salary] per month"
            } elseif {$display_pref == "year"} {
                 return "\$[format %6.2f [expr $salary * 12]] per year"
            } else {
                 return "\$[format %6.2f $salary] per $salary_period"
            }
        }
        year {
	    if {$display_pref == "month"} {
                 return "[format %6.2f [expr $salary/12]] per month"
            } elseif {$display_pref == "year"} {
                 return "\$[format %6.2f $salary] per year"
            } else {
                 return "\$[format %6.2f $salary] per $salary_period"
            }
        }
        default {
            return "\$[format %6.2f $salary] per $salary_period"
        }
    }
}

proc im_url {} {
    return "[ad_parameter SystemURL][im_url_stub]"
}

proc im_url_stub {} {
    return [ad_parameter IntranetUrlStub intranet]
}

proc im_enabled_p {} {
    return [ad_parameter IntranetEnabledP intranet 0]
}


# teadams on December 10th, 1999
# modified ad-new-stuff.tcl to work for the status reports
# I tried to extend ad_new_stuff to do so, but it got too hairy.
proc_doc im_status_report {db {coverage ""} {report_date "f"} {purpose "web_display"} {ns_share_list "im_status_report_section_list"}  } "Returns a string of new stuff on the site.  COVERAGE and REPORT_DATS are ANSI date.  The PURPOSE argument can be \"web_display\" (intended for an ordinary user), \"site_admin\" (to help the owner of a site nuke stuff), or \"email_summary\" (in which case we get plain text back).  These arguments are passed down to the procedures on the ns_share'd ns_share_list." {
    # let's default the date if we didn't get one

    if [empty_string_p $coverage] {
	set since_when [database_to_tcl_string $db "select sysdate from dual"]
    }
    if [empty_string_p $report_date] {
	set report_date [database_to_tcl_string $db "select sysdate from dual"]
    }
    ns_share $ns_share_list
    set result_list [list]

    # module_name_proc_history will ensure that we do not have duplicates in the 
    # status report, even if the same procedure is registered twice 
    # with ns_share_list
    set module_name_proc_history [list]

    foreach sublist [set $ns_share_list] {
	
	set module_name [lindex $sublist 0]
	set module_proc [lindex $sublist 1]

	if { [lsearch -exact $module_name_proc_history "${module_name}_$module_proc"] > -1 } {
	    # This is a duplicate call to the same procedure! Skip it
	    continue
	}

	set result_elt ""

	set subresult [eval "$module_proc $db $coverage $report_date $purpose"]

	if ![empty_string_p $subresult] {
	    # we got something, let's write a headline 
	    if { $purpose == "email_summary" } {
		append result_elt "[string toupper $module_name]\n\n"
	    } else {
		append result_elt "<h3>$module_name</h3>\n\n"
	    }
	    append result_elt $subresult
	    append result_elt "\n\n"
	    lappend result_list $result_elt
	}
    }

    return [join $result_list ""]
}

proc_doc im_reduce_spaces { string } {Replaces all consecutive spaces with one} {
    regsub -all {[ ]+} $string " " string
    return $string
}

proc_doc hours_sum_for_user { db user_id { on_which_table "" } { on_what_id "" } { number_days "" } } {Returns the total number of hours the specified user logged for whatever else is included in the arg list} {
    set criteria [list "user_id=$user_id"]
    if { ![empty_string_p $on_which_table] } {
	lappend criteria "on_which_table='[DoubleApos $on_which_table]'"
    }
    if { ![empty_string_p $on_what_id] } {
	lappend criteria "on_what_id = $on_what_id"
    }
    if { ![empty_string_p $number_days] } {
	lappend criteria "day >= sysdate - 7"
    }
    set where_clause [join $criteria "\n    and "]
    set num [database_to_tcl_string $db \
	    "select sum(hours) from im_hours where $where_clause"]
    return [util_decode $num "" 0 $num]
}

proc_doc hours_sum { db on_which_table on_what_id {number_days ""} } {Returns the total hours registered for the specified table and id } {
    if { [empty_string_p $number_days] } {
	set days_back_sql ""
    } else {
	set days_back_sql " and day >= sysdate-$number_days"
    }
    set num [database_to_tcl_string $db \
	    "select sum(hours)
               from im_hours
              where on_what_id=$on_what_id
                and on_which_table='[DoubleApos $on_which_table]'$days_back_sql"]
    return [util_decode $num "" 0 $num]
}


proc_doc im_random_employee_blurb { db } "Returns a random employee's photograph and a little bio" {

    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    set users_with_photos_list  [database_to_tcl_list $db \
	"select distinct u.user_id
           from users_active u, user_group_map ugm
          where u.user_id = ugm.user_id
            and ugm.group_id = [im_employee_group_id]
            and u.portrait is not null
            and u.user_id != [ad_get_user_id]"]

    if { [llength $users_with_photos_list] == 0 } {
	return ""
    }

    # get the lucky user
    set random_num [randomRange [expr [llength $users_with_photos_list] -1] ]
    set portrait_user_id [lindex $users_with_photos_list $random_num]

    # Since a user should be mapped to one and only one office, we
    # can join with user_group_map.
    #
    set selection [ns_db 0or1row $db \
	    "select u.first_names || ' ' || u.last_name as name, u.bio, info.skills, 
                    ug.group_name as office, ug.group_id as office_id
               from users u, im_employee_info info, user_groups ug, user_group_map ugm
              where u.user_id = info.user_id
                and u.user_id = ugm.user_id(+)
                and ug.group_id = ugm.group_id
                and ug.parent_group_id = [im_office_group_id]
                and u.user_id = $portrait_user_id
                and rownum < 2"]

    if { [empty_string_p $selection] } {
	return ""
    }

    set_variables_after_query
    
    # **** this should really be smart and look for the actual thumbnail
    # but it isn't and just has the browser smash it down to a fixed width
 
    return "
<a href=\"/shared/portrait.tcl?user_id=$portrait_user_id\"><img width=125 src=\"/shared/portrait-bits.tcl?user_id=$portrait_user_id\"></a>
<p>
Name: <a href=users/view.tcl?user_id=$portrait_user_id>$name</a>
<br>Office: <a href=offices/view.tcl?group_id=$office_id>$office</a>
[util_decode $bio "" "" "<br>Biography: $bio"]
[util_decode $skills "" "" "<br>Special skills: $skills"]
"

}


proc_doc im_restricted_access {} {Returns an access denied message and blows out 2 levels} {
    ad_return_error "Access denied" "You must be an employee of [ad_parameter SystemName] to see this page"
    return -code return
}

proc_doc im_allow_authorized_or_admin_only { db group_id current_user_id } {Returns an error message if the specified user is not able to administer the specified group or the user is not a site-wide/intranet administrator} {

    set user_admin_p [im_can_user_administer_group $db $group_id $current_user_id]

    if { ! $user_admin_p } {
	# We let all authorized users have full administrative control
	set user_admin_p [im_user_is_authorized_p $db $current_user_id]
    }

    if { $user_admin_p == 0 } {
	im_restricted_access
	return
    }
}


ad_proc im_groups_url {{-db "" -section "" -group_id "" -short_name ""}} {Sets up the proper url for the /groups stuff in acs} {
    if { [empty_string_p $group_id] && [empty_string_p $short_name] } {
	ad_return_error "Missing group_id and short_name" "We need either the short name or the group id to set up the url for the /groups directory"
    }
    if { [empty_string_p $short_name] } {
	if { [empty_string_p $db] } {
	    set db [ns_db gethandle subquery]
	    set release_db 1
	} else {
	    set release_db 0
	}
	set short_name [database_to_tcl_string $db \
		"select short_name from user_groups where group_id=$group_id"]
	if { $release_db } {
	    ns_db releasehandle $db
	}
    }
    if { ![empty_string_p $section] } {
	set section "/$section"
    }
    return "/groups/[ad_urlencode $short_name]$section"
}

proc_doc im_customer_group_id_from_user {} {Sets group_id and short_name in the calling environment of the first customer_id this proc finds for the logged in user} {
    uplevel {
	set local_user_id [ad_get_user_id]
	# set local_db [ns_db gethandle subquery]
	set selection [ns_db 0or1row $db \
		"select g.group_id, g.short_name
		   from user_groups g, user_group_map ugm 
		  where g.group_id=ugm.group_id
		    and g.parent_group_id=[im_customer_group_id]
		    and ugm.user_id=$local_user_id
		    and rownum<2"]
	if { [empty_string_p $selection] } {
	    set group_id ""
	    set short_name ""
	} else {
	    set_variables_after_query
	}
	# ns_db releasehandle $local_db
    }
}


proc_doc im_user_information { db user_id } {
Returns an html string of all the intranet applicable information for one 
user. This information can be used in the shared community member page, for 
example, to give intranet users a better understanding of what other people
are doing in the site.
} {

    set caller_id [ad_get_user_id]
    
    set return_url [ad_partner_url_with_query]

    # we need a backup copy
    set user_id_copy $user_id

    # If we're looking at our own entry, we can modify some information
    if {$caller_id == $user_id} {
	set looking_at_self_p 1
    } else {
	set looking_at_self_p 0
    }

    # can the user make administrative changes to this page
    set user_admin_p [im_is_user_site_wide_or_intranet_admin $db $caller_id]

    # is this user an employee?
    set user_employee_p [database_to_tcl_string $db \
	    "select decode ( ad_group_member_p ( $user_id, [im_employee_group_id] ), 'f', 0, 1 ) from dual"]

    set selection [ns_db 0or1row $db "\
	    select u.*, uc.*, info.*,
    ((sysdate - info.first_experience)/365) as years_experience
    from users u, users_contact uc, im_employee_info info
    where u.user_id = $user_id 
    and u.user_id = uc.user_id(+)
    and u.user_id = info.user_id(+)"]

    if [empty_string_p $selection] {
	ad_return_error "Error" "User doesn't exist"
	return -code return
    }
    set_variables_after_query

    # just in case user_id was set to null in the last query
    set user_id $user_id_copy

    set selection [ns_db select $db \
	    "select ug.group_name, ug.group_id
    from user_groups ug
    where ad_group_member_p ( $user_id, ug.group_id ) = 't'
    and ug.parent_group_id=[im_office_group_id]"]

    set offices ""
    set number_offices 0
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	incr number_offices
	if { ![empty_string_p $offices] } {
	    append offices ", "
	}
	append offices "  <a href=[im_url]/offices/view.tcl?[export_url_vars group_id]>$group_name</A>\n"
    }

    set page_content "<ul>\n"

    if [exists_and_not_null job_title] {
	append page_content "<LI>Job title: $job_title\n"
    }

    if { $number_offices == 0 } {
	if { $user_admin_p } {
	    append page_content "  <li>Office: <a href=[im_url]/users/add-to-office.tcl?[export_url_vars user_id return_url]>Add [util_decode $looking_at_self_p 1 yourself "this user"] to an office</a>\n"
	}

    } elseif { $user_employee_p } {
	append page_content "  <li>[util_decode $number_offices 1 Office Offices]: $offices\n"
    }

    if [exists_and_not_null years_experience] {
	append page_content "<LI>Job experience: [format %3.1f $years_experience] years\n"
    }

    if { [exists_and_not_null portrait_upload_date] } {
	if { $looking_at_self_p } {
	    append page_content "<p><li><a href=/pvt/portrait/index.tcl?[export_url_vars return_url]>Portrait</A>\n"
	} else {
	    append page_content "<p><li><a href=/shared/portrait.tcl?[export_url_vars user_id]>Portrait</A>\n"
	}
    } elseif { $looking_at_self_p } {
	append page_content "<p><li>Show everyone else at [ad_system_name] how great looking you are:  <a href=/pvt/portrait/upload.tcl?[export_url_vars return_url]>upload a portrait</a>"
    }

    append page_content "<p>"

    if [exists_and_not_null email] {
	append page_content "<LI>Email: <A HREF=mailto:$email>$email</A>\n";
    }
    if [exists_and_not_null url] {
	append page_content "<LI>Homepage: <A HREF=[im_maybe_prepend_http $url]>[im_maybe_prepend_http $url]</A>\n";
    }
    if [exists_and_not_null aim_screen_name] {
	append page_content "<LI>AIM name: $aim_screen_name\n";
    }
    if [exists_and_not_null icq_number] {
	append page_content "<LI>ICQ number: $icq_number\n";
    }
    if [exists_and_not_null work_phone] {
	append page_content "<LI>Work phone: $work_phone\n";
    }
    if [exists_and_not_null home_phone] {
	append page_content "<LI>Home phone: $home_phone\n";
    }
    if [exists_and_not_null cell_phone] {
	append page_content "<LI>Cell phone: $cell_phone\n";
    }


    set address [im_format_address [value_if_exists ha_line1] [value_if_exists ha_line2] [value_if_exists ha_city] [value_if_exists ha_state] [value_if_exists ha_postal_code]]

    if { ![empty_string_p $address] } {
	append page_content "
	<p><table cellpadding=0 border=0 cellspacing=0>
	<tr>
	<td valign=top><em>Home address: </em></td>
	<td>$address</td>
	</tr>
	</table>

	"
    }

    if [exists_and_not_null skills] {
	append page_content "<p><em>Special skills:</em> $skills\n";
    }

    if [exists_and_not_null educational_history] {
	append page_content "<p><em>Degrees/Schools:</em> $educational_history\n";
    }

    if [exists_and_not_null last_degree_completed] {
	append page_content "<p><em>Last Degree Completed:</em> $last_degree_completed\n";
    }

    if [exists_and_not_null bio] {
	append page_content "<p><em>Biography:</em> $bio\n";
    }

    if [exists_and_not_null note] {
	append page_content "<p><em>Other information:</em> $note\n";
    }

    if {$looking_at_self_p} {
	append page_content "<p>(<A HREF=[im_url]/users/info-update.tcl>edit</A>)\n"
    }



    append page_content "
    <p><i>Current projects:</i><ul>\n"

    set projects_html ""

    set selection [ns_db select $db \
	    "select user_group_name_from_id(group_id) as project_name,
    group_id as project_id, level
    from im_projects p
    where ad_group_member_p ( $user_id, p.group_id ) = 't'
    connect by prior group_id=parent_id
    start with parent_id is null"]

    set projects_html ""
    set current_level 1
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	if { $level > $current_level } {
	    append projects_html "  <ul>\n"
	    incr current_level
	} elseif { $level < $current_level } {
	    append projects_html "  </ul>\n"
	    set current_level [expr $current_level - 1]
	}	
	append projects_html "  <li><a href=[im_url]/projects/view.tcl?group_id=$project_id>$project_name</a>\n"
    }
    if { [exists_and_not_null level] && $level <= $current_level } {
	append projects_html "  </ul>\n"
    }	
    if { [empty_string_p $projects_html] } {
	set projects_html "  <li><i>None</i>\n"
    }

    append page_content "
    $projects_html
    </ul>
    "

    set selection [ns_db select $db "select to_char(start_date, 'Mon DD, YYYY') as start_date, to_char(end_date,'Mon DD, YYYY') as end_date, contact_info, initcap(vacation_type) as vacation_type, vacation_id,
    description from user_vacations where user_id = $user_id 
    and (start_date >= to_date(sysdate,'YYYY-MM-DD') or
    (start_date <= to_date(sysdate,'YYYY-MM-DD') and end_date >= to_date(sysdate,'YYYY-MM-DD')))
    order by start_date asc"]

    set office_absences ""
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	if { [empty_string_p $vacation_type] } {
	    set vacation_type "Vacation"
	}
	append office_absences "  <li><b>$vacation_type</b>: $start_date - $end_date, <br>$description<br>
	Contact info: $contact_info"

	if { $looking_at_self_p || $user_admin_p } {
	    append office_absences "<br><a href=[im_url]/vacations/edit.tcl?[export_url_vars vacation_id]>edit</a>"
	}
    }

    if { ![empty_string_p $office_absences] } {
	append page_content "
	<p>
	<i>Office Absences:</i>
	<ul>
	$office_absences
	</ul>
	"
    }

    if { [ad_parameter TrackHours intranet 0] && [im_user_is_employee_p $db $user_id] } {
	append page_content "
	<p><a href=[im_url]/hours/index.tcl?on_which_table=im_projects&[export_url_vars user_id]>View this person's work log</a>
	</ul>
	"
    }

    # don't sign it with the publisher's email address!
    append page_content "</ul>\n"
    return $page_content
}




proc_doc im_yes_no_table { yes_action no_action { var_list [list] } { yes_button " Yes " } {no_button " No "} } "Returns a 2 column table with 2 actions - one for yes and one for no. All the variables in var_list are exported into the to forms. If you want to change the text of either the yes or no button, you can ser yes_button or no_button respectively." {
    set hidden_vars ""
    foreach varname $var_list {
        if { [eval uplevel {info exists $varname}] } {
            upvar $varname value
            if { ![empty_string_p $value] } {
		append hidden_vars "<input type=hidden name=$varname value=\"[philg_quote_double_quotes $value]\">\n"
            }
        }
    }
    return "
<table>
  <tr>
    <td><form method=post action=\"[philg_quote_double_quotes $yes_action]\">
        $hidden_vars
        <input type=submit value=\"[philg_quote_double_quotes $yes_button]\">
        </form>
    </td>
    <td><form method=get action=\"[philg_quote_double_quotes $no_action]\">
        $hidden_vars
        <input type=submit value=\"[philg_quote_double_quotes $no_button]\">
        </form>
    </td>
  </tr>
</table>
"
}


proc_doc im_spam_multi_group_exists_clause { group_id_list } {
    returns a portion of an sql where clause that begins
    with " and exists..." and includes all the groups in the 
    comma separated list of group ids (group_id_list)
} {
    set criteria [list]
    foreach group_id [split $group_id_list ","] {
	lappend criteria "(select 1 from user_group_map ugm where u.user_id=ugm.user_id and ugm.group_id='$group_id')"
    }
    if { [llength $criteria] > 0 } {
	return " and exists [join $criteria " and exists "] "
    } else {
	return ""
    }
}

proc_doc im_spam_number_users { db group_id_list } {
    Returns the number of users that belong to all the groups in 
    the comma separated list of group ids (group_id_list)
} {
    set ugm_clause [im_spam_multi_group_exists_clause $group_id_list]
    return [database_to_tcl_string $db \
	    "select count(distinct u.user_id)
               from users_active u, user_group_map ugm
              where u.user_id=ugm.user_id $ugm_clause"]
}



util_report_successful_library_load
