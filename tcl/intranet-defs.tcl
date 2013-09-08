# /tcl/intranet-defs.tcl

ad_library {

    Definitions for the intranet module

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @author David Rodriguez (dvr@arsdigita.com)
    @author Tracy Adams (teadams@mit.edu)
    @cvs-id intranet-defs.tcl,v 3.151.2.34 2001/02/06 02:25:39 mbryzek Exp

}

# Basic Intranet Parameter Shortcuts

proc im_url_stub {} {
    return [ad_parameter IntranetUrlStub intranet "/intranet"]
}

proc im_url {} {
    return [ad_parameter SystemURL][im_url_stub]
}

proc im_enabled_p {} {
    return [ad_parameter IntranetEnabledP intranet 0]
}

# Intranet Security Filters

ns_share -init {set ad_intranet_security_filters_installed 0} ad_intranet_security_filters_installed

if {!$ad_intranet_security_filters_installed} {
    
    # we will bounce people out of /intranet if they don't have a cookie
    # and if they are not authorized users

    set intranet_stub [im_url_stub]
    # Note - if intranet_stub is empty, register an error as we can't put a filter on /*!
    if { [empty_string_p $intranet_stub] } {
	ns_log Error "intranet-defs.tcl: im_url_stub is undefined. SECURITY FILTERS INSTALLED ON /intranet"
	set intranet_stub "/intranet"
    } 

    ad_register_filter preauth * $intranet_stub/* im_user_is_authorized
    
    # protect the /employees/admin directory to either site-wide administrators
    # or intranet administrators
    ad_register_filter preauth * $intranet_stub/employees/admin/* im_verify_user_is_admin
    
    if { [ad_parameter ForceUsersToLogHoursP intranet 0] } {
	# preauth filter to ask people to log their hours. 
	ad_register_filter preauth GET $intranet_stub/* im_force_user_to_log_hours
    }
    
    if { [ad_parameter ForceUsersToEnterProjectReportsP intranet 0] } {
	# preauth filter to get people to fill in late project reports
	ad_register_filter preauth GET $intranet_stub/* im_force_user_to_enter_project_report
    }

    if { [ad_parameter EnableIntranetBBoardSecurityFiltersP intranet 0] } {
	ad_register_filter preauth * /bboard/* im_bboard_restrict_access_to_group
    }

    set ad_intranet_security_filters_installed 1

}


ad_proc im_user_group_member_p { user_id group_id } {
    Returns 1 if specified user is a member of the specified group. 0 otherwise
} {
    return [db_string user_member_of_group \
	    "select decode(ad_group_member_p(:user_id, :group_id), 't', 1, 0) from dual"]
}


ad_proc im_user_group_or_subgroup_member_p { user_id group_id } {
    Returns 1 if the user is a member of the specified group or of any
    subgroup of the specified group
} {
    return [db_string user_is_group_or_subgroup_member\
	    "select decode(count(ugm.group_id),0,0,1)
               from user_group_map ugm, user_groups ug
              where ugm.user_id = :user_id
                and ugm.group_id = ug.group_id
                and (ug.group_id = :group_id or ug.parent_group_id = :group_id)"]
    
}


ad_proc im_user_is_employee_p { user_id } {
    Returns 1 if a the user is in the employee group. 0 Otherwise
} {
    return [im_user_group_member_p $user_id [im_employee_group_id]]
}

ad_proc im_user_is_authorized {conn args why} {Returns filter_ok if user is employee} {
    set user_id [ad_verify_and_get_user_id]
    if { $user_id == 0 } {
	# Not logged in
	ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    }
    
    set is_authorized_p [im_user_is_authorized_p $user_id]
    if { $is_authorized_p > 0 } {
	return filter_ok
    } else {
	ad_return_forbidden "Access denied" "You must be an employee or otherwise authorized member of [ad_system_name] to see this page. You can <a href=/register/index?return_url=[ad_urlencode [im_url_with_query]]>login</a> as someone else if you like."
	return filter_return	
    }
}

ad_proc im_user_is_customer_p { user_id } {Returns 1 if a the user is in a customer group. 0 Otherwise} {
    return [im_user_group_or_subgroup_member_p $user_id [im_customer_group_id]]
}

ad_proc im_user_is_customer {conn args why} {Returns filter_of if user is customer} {
    set user_id [ad_get_user_id]
    if { $user_id == 0 } {
	# Not logged in
	ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    }
    
    set is_customer_p [im_user_is_customer_p $user_id]
    if { $is_customer_p > 0 } {
	return filter_ok
    } else {
	ad_return_forbidden "Access denied" "You must be a customer of [ad_system_name] to see this page"
	return filter_return	
    }
}

ad_proc im_verify_user_is_admin { conn args why } {Returns 1 if a the user is either a site-wide administrator or in the Intranet administration group} {
    set user_id [ad_verify_and_get_user_id]
    if { $user_id == 0 } {
	# Not logged in
	ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    }
    
    set val [im_is_user_site_wide_or_intranet_admin $user_id]
    if { $val > 0 } {
	return filter_ok
    } else {
	ad_return_forbidden "Access denied" "You must be an administrator of [ad_system_name] to see this page"
	return filter_return	
    }
}

proc im_task_general_comment_section {task_id name} {
    set spam_id [db_nextval "spam_id_sequence"]
    set return_url  "[im_url]/spam?return_url=[ns_conn url]?[export_ns_set_vars [list task_id spam_id]]&task_id=$task_id&spam_id=$spam_id"

    set html "
<em>Comments</em>
[ad_general_comments_summary $task_id im_tasks $name]
<P>
<center>
(<A HREF=\"/general-comments/comment-add?on_which_table=im_tasks&on_what_id=$task_id&item=[ns_urlencode $name]&module=intranet&return_url=[ns_urlencode $return_url]\">Add a comment</a>)
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

[im_url]/mailing-list/set-dont-spam-me-p?user_id=$user_id" 

    return $message
}

proc im_removal_instructions {user_id} {

    set message "
------------------------------
Sent through [im_url]
"

    return $message
}

proc im_spam {user_id_list from_address subject message spam_id {add_removal_instructions_p 0} } { 
    #Spams an user_id_list
    #Does not automatically add removal instructions
    set html ""
    set user_id [ad_get_user_id]    
    set status "sending"
    set peeraddr [ns_conn peeraddr]

    if { [catch [db_dml spam_history_insert {
	insert into spam_history
	(spam_id, from_address, title, body_plain, creation_date, creation_user, creation_ip_address, status)
	values
	(:spam_id, :from_address, :subject, empty_clob(), sysdate, :creation_user, :peeraddr, :status)
    } -clobs [list $body_plain]] errmsg] } {
    # choked; let's see if it is because 
	if { [db_string spam_history_count "select count(*) from spam_history where spam_id = :spam_id"] > 0 } {
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
    set failure_html ""
    set failure_count 0
    foreach mail_to_id $user_id_list {
	set email [db_string user_email "
	select email 
	from users_spammable 
	where user_id = :mail_to_id"]
	if { $email == 0 } {
	    incr failure_count
	    #get the failure persons' name if available.
	    set failed_name [catch { [db_string user_name "
	    select first_names || ' ' || last_name as name 
	    from users 
	    where user_id = :mail_to_id"] } "no name found" ]
	    append failure_html "<li> no email address was found for user_id = $mail_to_id: name = $failed_name"

	} else {
	    if { $add_removal_instructions_p } {
		append message [im_removal_instructions $mail_to_id]
	    }
	    ns_sendmail $email $from_address $subject $message	    
	    db_dml spam_update spam_history  -type update -where "spam_id = :spam_id" [list n_sent "n_sent+1"]
	    append sent_html "<li>$email...\n"
	}
    }
    set n_sent [db_string spam_number_sent "select n_sent from spam_history where spam_id = :spam_id"]
    db_dml spam_update_status "update spam_history set status = 'sent' where spam_id = :spam_id"
    
    append html "<blockquote>Email was sent $n_sent email addresses.  <p> If any of these addresses are bogus you will recieve a bounced email in your box<ul> $sent_html </ul> </blockquote>"
    if { $failure_count > 0 } {
	append html "They databased did not have email addresses or the user has requested that spam be blocked in the following $failure_count cases: 
	<ul> $failure_html </ul>"
    }
    return $html
}

proc im_name_in_mailto { user_id} {
    if { $user_id > 0 } {
	db_1row user_name_and_email \
		"select first_names || ' ' || last_name as name, email from users where user_id=:user_id"
	set mail_to "<a href=mailto:$email>$name</a>"
    } else {
	set mail_to "Unassigned"
    }
    return $mail_to
}

proc im_name_paren_email {user_id} {
    if { $user_id > 0 } {
	db_1row user_name_and_email \
		"select first_names || ' ' || last_name as name, email from users where user_id=:user_id"
	set text "$name: $email"
    } else {
	set text "Unassigned"
    }    
    return $text
}

proc im_db_html_select_value_options_plus_hidden {query list_name {select_option ""} {value_index 0} {label_index 1}} {
    #this is html to be placed into a select tag
    #when value!=option, set the index of the return list
    #from the db query. selected option must match value
    #it also sends a hidden variable with all the values 
    #designed to be availavle for spamming a list of user ids from the next page.

    set select_options ""
    set values_list ""
    set options [db_list_of_lists im_db_html_select_random_query $query]
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

proc im_employee_select_optionlist { {user_id ""} } {
    return [db_html_select_value_options -select_option $user_id im_employee_select_options "select
u.user_id , u.last_name || ', ' || u.first_names as name
from im_employees_active u
order by lower(name)"]
}

ad_proc im_num_employees {{since_when ""} {report_date ""} {purpose ""} {user_id ""}} "Returns string that gives # of employees and full time equivalents" {

    set num_employees [db_string employees_total_number \
	    "select count(time.percentage_time) 
               from im_employees_active emp, im_employee_percentage_time time
              where (time.percentage_time is not null and time.percentage_time > 0)
                and (emp.start_date < sysdate)
                and time.start_block = to_date(next_day(sysdate-8, 'SUNDAY'), 'YYYY-MM-DD')
                and time.user_id=emp.user_id"]

    set num_fte [db_string employee_total_fte \
	    "select sum(time.percentage_time) / 100
               from im_employees_active emp, im_employee_percentage_time time
              where (time.percentage_time is not null and time.percentage_time > 0)
                and (emp.start_date < sysdate)
                and time.start_block = to_date(next_day(sysdate-8, 'SUNDAY'), 'YYYY-MM-DD')
                and time.user_id=emp.user_id"]

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

ad_proc im_num_employees_simple { } "Returns # of employees." {
    return [db_string employees_count_total \
	    "select count(time.percentage_time) 
               from im_employees_active info, im_employee_percentage_time  time
              where (time.percentage_time is not null and time.percentage_time > 0)
                and (info.start_date < sysdate)
                and time.start_block = to_date(next_day(sysdate-8, 'SUNDAY'), 'YYYY-MM-DD')
                and time.user_id=info.user_id"]
}

ad_proc im_num_offices_simple { } "Returns # of offices." {
    return [db_string offices_count_total \
	    "select count(*) 
               from user_groups
              where parent_group_id = [im_office_group_id]"]
}


ad_proc im_allocation_date_optionlist { {start_block ""} {start_of_larger_unit_p ""} { number_months_ahead 18 } } {
    Returns an optionlist of valid allocation start dates. If
    start_of_larger_unit_p is t/f, then we limit to those blocks matching
    t/f. Number_months_ahead specified the number of months of start
    blocks from today to include. This is great for limiting the size of
    select bars. Specifying a negative value includes all of the start
    blocks.
} {
 
    set bind_vars [ns_set create]
    if { [empty_string_p $start_of_larger_unit_p] } {
	set start_p_sql ""
    } else {
	ns_set put $bind_vars start_of_larger_unit_p $start_of_larger_unit_p
	set start_p_sql " and start_of_larger_unit_p=:start_of_larger_unit_p "
    }
    if { $number_months_ahead < 0 } {
	set number_months_sql ""
    } else {
	ns_set put $bind_vars number_months_ahead $number_months_ahead
	set number_months_sql " and start_block <= add_months(sysdate, :number_months_ahead) "
    }
    # Only go as far as 1 year into the future to save space
    return [db_html_select_value_options -bind $bind_vars -select_option $start_block allocations_near_future \
	    "select start_block, to_char(start_block,'Month YYYY')
               from im_start_blocks 
              where to_char(start_block,'W') = 1 $number_months_sql $start_p_sql
              order by start_block asc"]
}

ad_proc im_list_late_project_report_groups_for_user { user_id { number_days 7 } } {
    Returns a list of all the groups and group ids for which the
    user is late entering in a report. The ith element is the group name,
    the i+1st element is the group_id. This function simply hides the
    complexity of the late_project_report query
} {

    set project_report_type_as_survey_list [list]
    set survey_report_types_list [list]
    foreach type_survey_pair  [ad_parameter_all_values_as_list ProjectReportTypeSurveyNamePair intranet] {
	set type_survey_list [split $type_survey_pair ","]
	set type [lindex $type_survey_list 0]
	set survey [lindex $type_survey_list 1]
	# we found a project type done with a survey
	
	lappend project_report_type_as_survey_list [string tolower $type]
	lappend survey_report_types_list [string tolower $survey]
    }

    # We generate a list of the criteria out here to try to make the query more readable

    set criteria [list "p.requires_report_p='t'" "u.user_id='$user_id'"]
    # Only open projects need project reports
    lappend criteria "p.project_status_id = (select project_status_id 
                                               from im_project_status
                                              where project_status='Open')" 
    
    # We have mulitple reports - those for project types listed in the .ini file
    # and general comments for others.

    # Check reports that need general_comments reports
    if { [llength $project_report_type_as_survey_list] == 0 } {
	set general_comments_reports \
		"not exists  (select 1 
                                    from general_comments gc
                                   where gc.comment_date > sysdate - $number_days
                                     and on_which_table = 'user_groups'
                                     and on_what_id = p.group_id)"
	lappend criteria $general_comments_reports
    } else {
	set general_comments_reports \
	    "lower(project_type) not in ('[join  $project_report_type_as_survey_list "','"]')
               and not exists  (select 1 
                                  from general_comments gc
                                 where gc.comment_date > sysdate - $number_days
                                   and on_which_table = 'user_groups'
                                   and on_what_id = p.group_id)"
    
	# With project types that need survey reports, we check two things:
	#   1. that a survey actually exists for the user to fill out
	#   2. It's filled out if it exists.
	#
	set survey_reports \
	    "lower(project_type) in ('[join  $project_report_type_as_survey_list "','"]')
               and exists (select 1
                             from survsimp_surveys
                            where short_name in ('[join  $survey_report_types_list "','"]'))
               and not exists (select 1
                                 from survsimp_responses
                                where survey_id=(select survey_id 
                                                   from survsimp_surveys
                                                  where short_name in ('[join  $survey_report_types_list "','"]'))
                                  and submission_date > sysdate - $number_days
                                  and group_id=p.group_id)"

	lappend criteria "( ($general_comments_reports) or ($survey_reports) )"
    }
    set where_clause [join $criteria "\n         and "]

    # Not binding the variables in this query because of the dynamic where clause
    set sql "select g.group_name, g.group_id
               from user_groups g, im_projects p, im_employees_active u, im_project_types
              where p.project_lead_id = u.user_id
                and p.project_type_id = im_project_types.project_type_id
                and p.group_id=g.group_id
                and $where_clause"

    set group_list [list]
    db_foreach late_reports_for_user $sql {
	lappend group_list $group_name $group_id
    }
    return $group_list
}

ad_proc im_late_project_reports {user_id {html_p "t"} { number_days 7 } } "Returns either a text or html block describing late project reports" {
    set return_string ""

    foreach { group_name group_id } [im_list_late_project_report_groups_for_user $user_id $number_days] {
	if {$html_p == "t"} {
	    append return_string "<li><b>Late project report:</b> <a href=[im_url_stub]/projects/report-add?[export_url_vars group_id]>$group_name</a>"
	} else {
	    append return_string "$group_name: 
  [im_url]/projects/report-add?[export_url_vars group_id]

"
	}
	
    }
    return $return_string
}

ad_proc im_slider { field_name pairs { default "" } { var_list_not_to_export "" } } {
    Takes in the name of the field in the current menu bar and a list where the ith item is the name of the form element and the i+1st element is the actual text to display. Returns an html string of the properly formatted slider bar
} {
    if { [llength $pairs] == 0 } {
	# Get out early as there's nothing to do
	return ""
    }
    if { [empty_string_p $default] } {
	set default [ad_partner_upvar $field_name 1]
    }
    set exclude_var_list [list $field_name]
    foreach var $var_list_not_to_export {
	lappend exclude_var_list $var
    }
    set url "[ns_conn url]?"
    set query_args [export_ns_set_vars url $exclude_var_list]
    if { ![empty_string_p $query_args] } {
	append url "$query_args&"
    }
    set menu_items_text [list]
    # Count up the number of characters we display to help us select either
    # text links or a select box
    set text_length 0
    foreach { value text } $pairs {
	set text_length [expr $text_length + [string length $text]]
	if { [string compare $value $default] == 0 } {
	    lappend menu_items_text "<b>$text</b>\n"
	    lappend menu_items_select "<option value=\"[ad_urlencode $value]\" selected>$text\n"
	} else {
	    lappend menu_items_text "<a href=\"$url$field_name=[ad_urlencode $value]\">$text</a>\n"
	    lappend menu_items_select "<option value=\"[ad_urlencode $value]\">$text\n"
	}
    }
    if { $text_length > [ad_parameter LengthBeforeSelectBar intranet 50] } {
	# We have enough text - switch to a select bar
	return "
<form method=get action=\"[ns_conn url]\">
[export_ns_set_vars form $exclude_var_list]
<select name=\"[ad_quotehtml $field_name]\">
[join $menu_items_select ""]
</select>
<input type=submit value=\"Go\">
</form>
"
    } else {
	# Return simple text links
	return [join $menu_items_text " | "]
    }
}

ad_proc im_format_number { num {tag "<font size=\"+1\" color=\"blue\">"} } {
    Pads the specified number with the specified tag
} {
    regsub {\.$} $num "" num
    return "$tag${num}.</font>"
}

ad_proc im_verify_form_variables required_vars {
    The intranet standard way to verify arguments. Takes a list of
    pairs where the first element of the pair is the variable name and the
    second element of the pair is the message to display when the variable
    isn't defined.
} {
    set err_str ""
    foreach pair $required_vars {
	if { [catch { 
	    upvar [lindex $pair 0] value
	    if { [empty_string_p [string trim $value]] } {
		append err_str "  <li> [lindex $pair 1]\n"
	    } 
	} err_msg] } {
	    # This means the variable is not defined - the upvar failed
	    append err_str "  <li> [lindex $pair 1]\n"
	} 
    }	
    return $err_str
}

ad_proc im_append_list_to_ns_set { { -integer_p f } set_id base_var_name list_of_items } {
    Iterates through all items in list_of_items. Adds to set_id
    key/value pairs like <var_name_0, item_0>, <var_name_1, item_1>
    etc. Returns a comma separated list of the bind variables for use in
    sql. Executes validate-integer on every element if integer_p is set to t
} {
    set ctr 0
    set sql_string_list [list]
    foreach item $list_of_items {
	if { $integer_p == "t" } {
	    validate_integer "${base_var_name} element" $item
	}
	set var_name "${base_var_name}_$ctr"
	ns_set put $set_id $var_name $item
	lappend sql_string_list ":$var_name"
	incr ctr
    }
    return [join $sql_string_list ", "]
}


ad_proc im_customer_select { select_name { default "" } { status "" } { exclude_status "" } } {
    
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the customers in the system. If status is
    specified, we limit the select box to customers that match that
    status. If exclude status is provided, we limit to states that do not
    match exclude_status (list of statuses to exclude).

} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars customer_group_id [im_customer_group_id]

    set sql "select ug.group_id, ug.group_name
             from user_groups ug, im_customers c
             where ug.parent_group_id=:customer_group_id
               and ug.group_id = c.group_id(+)"
    if { ![empty_string_p $status] } {
	ns_set put $bind_vars status $status
	append sql " and customer_status_id=(select customer_status_id from im_customer_status where customer_status=:status)"
    }


    if { ![empty_string_p $exclude_status] } {
	set exclude_string [im_append_list_to_ns_set $bind_vars customer_status_type $exclude_status]
	append sql " and customer_status_id in (select customer_status_id 
                                                  from im_customer_status 
                                                 where customer_status not in ($exclude_string)) "
    }
    append sql " order by lower(group_name)"
    return [im_selection_to_select_box $bind_vars "customer_status_select" $sql $select_name $default]
}

ad_proc im_project_select { select_name { default "" } { status "" } {type ""} { exclude_status "" } } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the projects in the system. If status is
    specified, we limit the select box to projects matching that
    status. If type is specified, we limit the select box to project
    matching that type. If exclude_status is provided as a list, we
    limit to states that do not match any states in exclude_status.
 } {
     set bind_vars [ns_set create]
     ns_set put $bind_vars project_group_id [im_project_group_id]

    set sql "select ug.group_id, ug.group_name
             from user_groups ug, im_projects p
             where ug.parent_group_id=:project_group_id
               and ug.group_id = p.group_id(+)"

    if { ![empty_string_p $status] } {
	ns_set put $bind_vars status $status
	append sql " and project_status_id=(select project_status_id from im_project_status where project_status=:status)"
    }

    if { ![empty_string_p $exclude_status] } {
	set exclude_string [im_append_list_to_ns_set $bind_vars project_status $exclude_status]
	append sql " and project_status_id in (select project_status_id 
                                                  from im_project_status 
                                                 where project_status not in ($exclude_string)) "
    }
    if { ![empty_string_p $type] } {
	ns_set put $bind_vars type $type
	append sql " and project_type_id=(select project_type_id from im_project_types where project_type=:type)"
    }
    append sql " order by lower(group_name)"
    return [im_selection_to_select_box $bind_vars project_select $sql $select_name $default]
}

proc im_category_select { category_type select_name { default "" } } {
    set bind_vars [ns_set create]
    ns_set put $bind_vars category_type $category_type
    set sql "select category_id,category
             from categories
             where category_type = :category_type
             order by lower(category)"
    return [im_selection_to_select_box $bind_vars category_select $sql $select_name $default]
}    

ad_proc im_customer_status_select { select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the customer status_types in the system} {
    return [im_category_select "Intranet Customer Status" $select_name $default]
}

ad_proc im_customer_type_select { select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the customer types in the system} {
    return [im_category_select "Intranet Customer Type" $select_name $default]
}

ad_proc im_partner_status_select { select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the partner statuses in the system} {
    return [im_category_select "Intranet Partner Status" $select_name $default]
}

ad_proc im_partner_type_select { select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the project_types in the system} {
    return [im_category_select "Intranet Partner Type" $select_name $default]
}

ad_proc im_project_type_select { select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the project_types in the system} {
    return [im_category_select "Intranet Project Type" $select_name $default]
}

ad_proc im_project_status_select { select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the project_types in the system} {
    return [im_category_select "Intranet Project Status" $select_name $default]
}

ad_proc im_project_parent_select { select_name { default "" } {current_group_id ""} { status "" } { exclude_status "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the eligible projects for parents} {
    set bind_vars [ns_set create]
    if { [empty_string_p $current_group_id] } {
	set limit_group_sql ""
    } else {
	ns_set put $bind_vars current_group_id $current_group_id
	set limit_group_sql " and p.group_id != :current_group_id"
    }
    set status_sql ""
    if { ![empty_string_p $status] } {
	ns_set put $bind_vars status $status
	set status_sql "and p.project_status_id=(select project_status_id from im_project_status where project_status=:status)"
    } elseif { ![empty_string_p $exclude_status] } {
	set exclude_string [im_append_list_to_ns_set $bind_vars project_status $exclude_status] 
	set status_sql " and p.project_status_id in (select project_status_id 
                                                       from im_project_status 
                                                      where project_status not in ($exclude_string)) "
    }

    set sql "select g.group_id, g.group_name
               from user_groups g, im_projects p 
              where p.parent_id is null 
                and g.group_id=p.group_id(+) $limit_group_sql $status_sql
              order by lower(g.group_name)"
    return [im_selection_to_select_box $bind_vars parent_project_select $sql $select_name $default]
}

ad_proc im_selection_to_select_box { bind_vars statement_name sql select_name { default "" } } {Expects selection to have a column named id and another named name. Runs through the selection and return a select bar named select_name, defaulted to $default } {
    return "
<select name=\"$select_name\">
<option value=\"\"> -- Please select --
[db_html_select_value_options -bind $bind_vars -select_option $default $statement_name $sql]
</select>
"
}

ad_proc im_user_select { select_name { default "" } } {Returns an html select box named $select_name and defaulted to $default with a list of all the available project_leads in the system} {

    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    set bind_vars [ns_set create]
    ns_set put $bind_vars employee_group_id [im_employee_group_id]
    set sql "select emp.user_id, emp.last_name || ', ' || emp.first_names as name
from im_employees_active emp
order by lower(name)"
    return [im_selection_to_select_box $bind_vars project_lead_list $sql $select_name $default]
}

ad_proc im_group_id_from_parameter { parameter } {
    Returns the group_id for the group with the GroupShortName
    specified in the server .ini file for $parameter. That is, we look up
    the specified parameter in the intranet module of the parameters file,
    and use that short_name to find a group id. Memoizes the result
} {

    set short_name [ad_parameter $parameter intranet]
    if { [empty_string_p $short_name] } {
	ad_return_error "Error: Missing parameter" "The parameter \"$parameter\" is not defined in the intranet section of your server's parameters file. Please define this parameter, restart your server, and try again. 
<p>Note: You can find all the current intranet parameters at <a href=http://software.arsdigita.com/parameters/ad.ini>http://software.arsdigita.com/parameters/ad.ini</a>, though this file may be more recent than your version of the ACS."
	ad_script_abort
    }

    return [util_memoize "im_group_id_from_parameter_helper $short_name"]
}

ad_proc im_group_id_from_parameter_helper { short_name } {
    Returns the group_id for the user_group with the specified
    short_name. If no such group exists, returns 0 
} {
    return [db_string user_group_id_from_short_name \
 	     "select group_id 
                from user_groups 
               where short_name=:short_name" -default 0]
}

ad_proc im_maybe_prepend_http { orig_query_url } {Prepends http to query_url unless it already starts with http://} {
    set orig_query_url [string trim $orig_query_url]
    set query_url [string tolower $orig_query_url]
    if { [empty_string_p $query_url] || [string compare $query_url "http://"] == 0 } {
	return ""
    }
    if { [regexp {^http://.+} $query_url] } {
	return $orig_query_url
    }
    return "http://$orig_query_url"
}

ad_proc im_table_with_title { title body } {Returns a two row table with background colors} {
    return "
<table width=100% cellpadding=2 cellspacing=2 border=0>
  <tr bgcolor=\"[ad_parameter TableColorHeader intranet white]\">
    <td><b><font size=-1>$title</font></b></td>
  </tr>
  <tr bgcolor=\"[ad_parameter TableColorOdd intranet white]\">
    <td><font size=-1>$body</font></td>
  </tr>
</table>
"
}

ad_proc im_users_in_group { group_id current_user_id { description "" } { add_admin_links 0 } { return_url "" } { limit_to_users_in_group_id "" } { dont_allow_users_in_group_id "" } { link_type "" } { also_add_to_group_id "" } } {

    Returns an html formatted list of all the users in the specified
    group. Includes optional links to add people, add/remove yourself, and spam

    Required Arguments:
    -------------------
    - group_id: Group we're interested in. We'll display the users in this group
    - current_user_id: The user_id of the person viewing the page that
       called this function. This is used to add links like "Add yourself"...

    Optional Arguments:
    -------------------
    - description: A description of the group. We use pass this to the
       spam function for UI
    - add_admin_links: Boolean. If 1, we add links to add/email
       people. Current user must be member of the specified group_id to add
       him/herself
    - return_url: Where to go after we do something like add a user
    - limit_to_users_in_group_id: Only shows users who belong to
       group_id and who are also members of the group specified in
       limit_to_users_in_group_id. For example, if group_id is an intranet
       project, and limit_to_users_group_id is the group_id of the employees
       group, we only display users who are members of both the employees and
       this project groups
    - dont_allow_users_in_group_id: Similar to
       limit_to_users_in_group_id, but says that if a user belongs to the
       group_id specified by dont_allow_users_in_group_id, then don't display
       that user.  
    - link_type: if set to "email_only" then the links returned have no html tags
    - also_add_to_group_id: If we're adding users to a group, we might
       also want to add them to another group at the same time. If you set
       also _add_to_group_id to a group_id, the user will be added first to
       group_id, then to also_add_to_group_id. Note that adding the person to
       both groups is NOT atomic.

    Notes:
    -------------------
    This function has quickly grown out-of-hand with all the
    additional flags needed. Originally, it seemed like a good idea to
    encapsulate the admin functions for intranet
    projects/customers/etc. in one piece of reusable code. However, it
    would be more useful in the future to create separate functions for
    each category of group in the intranet, and to use ad_proc to allow
    for cleaner extension.

} {
    set html ""
    if { [empty_string_p $limit_to_users_in_group_id] } {
	set limit_to_group_id_sql ""
    } else {
	set limit_to_group_id_sql "and exists (select 1 
                                                 from user_group_map map2, user_groups ug
                                                where map2.group_id = ug.group_id
                                                  and map2.user_id = users.user_id 
                                                  and (map2.group_id = :limit_to_users_in_group_id 
                                                       or ug.parent_group_id = :limit_to_users_in_group_id))"
    } 
    if { [empty_string_p $dont_allow_users_in_group_id] } {
	set dont_allow_sql ""
    } else {
	set dont_allow_sql "and not exists (select 1 
                                              from user_group_map map2, user_groups ug
                                             where map2.group_id = ug.group_id
                                               and map2.user_id = users.user_id 
                                               and (map2.group_id = :dont_allow_users_in_group_id 
                                                    or ug.parent_group_id = :dont_allow_users_in_group_id))"
    } 

    # We need a "distinct" because there can be more than one
    # mapping between a user and a group, one for each role.
    #
    set sql_post_select "from users_active users, user_group_map map
where map.user_id = users.user_id
and map.group_id = :group_id
$limit_to_group_id_sql $dont_allow_sql
order by lower(users.last_name)"

    set sql_query "select distinct
 users.user_id, users.email, users.first_names || ' ' || users.last_name as name, users.last_name
$sql_post_select"
                     
    set found 0
    set count 0
    db_foreach users_in_group $sql_query {
	incr count
	if { $current_user_id == $user_id } {
	    set found 1
	}
	if { $link_type == "email_only" } {
	    append html "  <li><a href=\"mailto:$email\">$name</a>\n"
	} else {
	    append html "  <li><a href=../users/view?[export_url_vars user_id]>$name</a>"
	}
	if { $add_admin_links } {
	    append html " (<a href=[im_url_stub]/member-remove-2?[export_url_vars user_id group_id return_url]>remove</a>)"
	}
	append html "\n"
    }
    
    if { [empty_string_p $html] } {
	set html "  <li><i>none</i>\n"
    }

    if { $add_admin_links } {

	if { $current_user_id > 0 } {
	    append html "  <p><a href=[im_url_stub]/member-add?role=member&subgroups_p=t&[export_url_vars group_id return_url limit_to_users_in_group_id also_add_to_group_id]>Add a person</a>"
	    if { $found } {
		append html "  <br><a href=[im_url_stub]/member-remove-2?[export_url_vars group_id return_url limit_to_users_in_group_id]&user_id=$current_user_id>Remove yourself</a>"
	    } else {
		# We might not want to offer this user the chance to add him/herself (based on the 
		# group_id set by limit_to_users_in_group_id)
		if { [empty_string_p $dont_allow_users_in_group_id] } {
		    set offer_link 1
		} else {
		    set offer_link [db_string group_limit_to_user \
			    "select decode(decode(count(*),0,0,1),1,0,1)
                               from user_group_map ugm, user_groups ug
                              where ugm.group_id = ug.group_id
                                and ugm.user_id=:current_user_id
                                and (ugm.group_id=:dont_allow_users_in_group_id 
                                     or ug.parent_group_id=:dont_allow_users_in_group_id)"]
		}
		if { $offer_link } {
		    # make sure the user is in the limiting group before adding him/her!
		    set offer_link_user_member_p [db_string user_group_member_p \
			    "select decode(count(*),0,0,1) 
                               from user_group_map ugm, user_groups ug
                              where ugm.group_id = ug.group_id
                                and ugm.user_id = :current_user_id
                                and (ugm.group_id = :limit_to_users_in_group_id 
                                     or ug.parent_group_id = :limit_to_users_in_group_id)"]
		    if { $offer_link_user_member_p } {
			append html "  <br><a href=[im_url_stub]/member-add-3?[export_url_vars group_id limit_to_users_in_group_id return_url also_add_to_group_id]&user_id_from_search=$current_user_id&role=administrator>Add yourself</a>"
		    }
		}
	    }
	    if { $count > 0 } {
		set group_id_list "${group_id},$limit_to_users_in_group_id"
		append html "  <br><a href=[im_url_stub]/spam/index?[export_url_vars group_id_list description return_url]>Spam people</a>"

		# If we have subprojects, then provide option to spam them
		set subgroup_ids [db_list subgroup_list_ids \
			"select group_id from im_projects where parent_id = :group_id"]
		if { [llength $subgroup_ids] > 0 } {
		    set group_id_list "${group_id},[join $subgroup_ids ","]"
		    append html "  <br><a href=[im_url_stub]/spam/index?[export_url_vars group_id_list description return_url]&all_or_any=any>Spam people in subprojects</a>"
		}
	    }
	}
    }
    return $html
}

ad_proc im_format_address { street_1 street_2 city state zip } {Generates a two line address with appropriate punctuation. } {
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

ad_proc im_can_user_administer_group { { group_id "" } { user_id "" } } { An intranet user can administer a given group if thery are a site-wide intranet user, a general site-wide administrator, or if they belong to the specified user group } {
    if { [empty_string_p $user_id] } {
	set user_id [ad_get_user_id]
    }
    if { $user_id == 0 } {
	return 0
    }
    set site_wide_or_intranet_user [im_is_user_site_wide_or_intranet_admin $user_id] 
    
    if { $site_wide_or_intranet_user } {
	return 1
    }

    # Else, if the user is in the group with any role, s/he can administer that group
    return [im_user_group_member_p $user_id $group_id]

}

ad_proc im_is_user_site_wide_or_intranet_admin { { user_id "" } } { Returns 1 if a user is a site-wide administrator or a member of the intranet administrative group } {
    if { [empty_string_p $user_id] } {
	set user_id [ad_verify_and_get_user_id]
    }
    if { $user_id == 0 } {
	return 0
    }
    if { [im_user_intranet_admin_p $user_id] } {
	# Site-Wide Intranet Administrator
	return 1
    } elseif { [ad_permission_p site_wide "" "" $user_id] } {
	# Site-Wide Administrator
	return 1
    } 
    return 0
}

ad_proc im_user_intranet_admin_p { user_id } {
    returns 1 if the user is an intranet admin (ignores site-wide admin permissions)
} {
    return [ad_administration_group_member "intranet" "" $user_id]
}

ad_proc im_user_is_authorized_p { user_id { second_user_id "0" } } {
    Returns 1 if a the user is authorized for the system. 0
    Otherwise. Note that the second_user_id gives us a way to say that
    this user is inded authorized to see information about another
    particular user (by being in a common group with that user).
} {
    set employee_group_id [im_employee_group_id]
    set authorized_users_group_id [im_authorized_users_group_id]
    set authorized_p [db_string user_in_authorized_intranet_group \
	    "select decode(count(*),0,0,1) as authorized_p
               from user_group_map 
              where user_id=:user_id 
                and (group_id=:employee_group_id
                     or group_id=:authorized_users_group_id)"]

    if { $authorized_p == 0 } {
	set authorized_p [im_is_user_site_wide_or_intranet_admin $user_id]
    }
    if { $authorized_p == 0 && $second_user_id > 0 } {
	# Let's see if this user is looking at someone else in one of their groups...
	# We let people look at other people in the same groups as them.
	set authorized_p [db_string user_in_two_groups \
		"select decode(count(*),0,0,1) as authorized_p
                   from user_group_map ugm, user_group_map ugm2
                  where ugm.user_id=:user_id
                    and ugm2.user_id=:second_user_id
                    and ugm.group_id=ugm2.group_id"]
    }
    return $authorized_p 
}

ad_proc im_project_group_id { } {Returns the groud_id for projects} {
    return [im_group_id_from_parameter ProjectGroupShortName]
}

ad_proc im_employee_group_id { } {Returns the groud_id for employees} {
    return [im_group_id_from_parameter EmployeeGroupShortName]
}

ad_proc im_customer_group_id { } {Returns the groud_id for customers} {
    return [im_group_id_from_parameter CustomerGroupShortName]
}

ad_proc im_partner_group_id { } {Returns the groud_id for partners} {
    return [im_group_id_from_parameter PartnerGroupShortName]
}

ad_proc im_office_group_id { } {Returns the groud_id for offices} {
    return [im_group_id_from_parameter OfficeGroupShortName]
}

ad_proc im_team_group_id { } {Returns the groud_id for teams} {
    return [im_group_id_from_parameter TeamGroupShortName]
}

ad_proc im_authorized_users_group_id { } {Returns the groud_id for offices} {
    return [im_group_id_from_parameter AuthorizedUsersGroupShortName]
}

ad_proc im_burn_rate_blurb { } {Counts the number of employees with payroll information and returns "The company has $num_employees employees and a monthly payroll of $payroll"} {
    # We use "exists" instead of a join because there can be more
    # than one mapping between a user and a group, one for each role,
    #
    set group_id [im_employee_group_id]
    db_1row employees_on_payroll "select count(u.user_id) as num_employees, 
ltrim(to_char(sum(salary),'999G999G999G999')) as payroll,
sum(decode(salary,NULL,1,0)) as num_missing
from im_monthly_salaries salaries, users u
where exists (select 1
              from user_group_map ugm
              where ugm.user_id = u.user_id
              and ugm.group_id = :group_id)
and u.user_id = salaries.user_id (+)"

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

ad_proc im_display_salary {salary salary_period} {Formats salary for nice display} {

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

ad_proc im_reduce_spaces { string } {Replaces all consecutive spaces with one} {
    regsub -all {[ ]+} $string " " string
    return $string
}

ad_proc hours_sum_for_user { user_id { on_which_table "" } { on_what_id "" } { number_days "" } } {
    Returns the total number of hours the specified user logged for
    whatever else is included in the arg list 
} {

    set criteria [list "user_id=:user_id"]
    if { ![empty_string_p $on_which_table] } {
	lappend criteria "on_which_table=:on_which_table"
    }
    if { ![empty_string_p $on_what_id] } {
	lappend criteria "on_what_id = :on_what_id"
    }
    if { ![empty_string_p $number_days] } {
	lappend criteria "day >= sysdate - :number_days"	
    }
    set where_clause [join $criteria "\n    and "]
    set num [db_string hours_sum \
	    "select sum(hours) from im_hours where $where_clause"]

    return [util_decode $num "" 0 $num]
}

ad_proc hours_sum { on_which_table on_what_id {number_days ""} } {
    Returns the total hours registered for the specified table and
    id. 
} {

    if { [empty_string_p $number_days] } {
	set days_back_sql ""
    } else {
	set days_back_sql " and day >= sysdate-:number_days"
    }
    set num [db_string hours_sum_for_group \
	    "select sum(hours)
               from im_hours
              where on_what_id = :on_what_id
                and on_which_table = :on_which_table $days_back_sql"]
    return [util_decode $num "" 0 $num]
}

ad_proc im_random_employee_blurb { } "Returns a random employee's photograph and a little bio" {
    
    # Get the current user id to not show the current user's portrait
    set current_user_id [ad_get_user_id]

    # How many photos are there?
    set number_photos [db_string number_employees_with_photos {
        select count(emp.user_id)
	  from im_employees_active emp, general_portraits  gp
 	 where emp.user_id <> :current_user_id
	   and emp.user_id = gp.on_what_id
	   and gp.on_which_table = 'USERS'
	   and gp.approved_p = 't'
	   and gp.portrait_primary_p = 't'}]

    if { $number_photos == 0 } {
        return ""
    }

    # get the lucky user
    #  Thanks to Oscar Bonilla <obonilla@fisicc-ufm.edu> who
    #  pointed out that we were previously ignoring the last user
    #  in the list
    set random_num [expr [randomRange $number_photos] + 1]
    # Using im_select_row_range means we actually only will retrieve the
    # 1 row we care about
    set sql "select emp.user_id
               from im_employees_active emp, general_portraits gp
              where emp.user_id <> :current_user_id
	        and emp.user_id = gp.on_what_id
		and gp.on_which_table = 'USERS'
		and gp.approved_p = 't'
		and gp.portrait_primary_p = 't'"

    set portrait_user_id [db_string random_user_with_photo \
	    [im_select_row_range $sql $random_num $random_num]]
 
    # We use rownum<2 in case the user is mapped to more than one office
    #
    set office_group_id [im_office_group_id]
    if { ![db_0or1row random_employee_get_info \
	    "select u.first_names || ' ' || u.last_name as name, u.bio, u.skills, 
                    ug.group_name as office, ug.group_id as office_id
               from im_employees_active u, user_groups ug, user_group_map ugm
              where u.user_id = ugm.user_id(+)
                and ug.group_id = ugm.group_id
                and ug.parent_group_id = :office_group_id
                and u.user_id = :portrait_user_id
                and rownum < 2"] } {
        # No lucky employee :(
	return ""
    }

    # **** this should really be smart and look for the actual thumbnail
    # but it isn't and just has the browser smash it down to a fixed width
 
    return "
<a href=\"/shared/portrait?user_id=$portrait_user_id\"><img width=125 src=\"/shared/portrait-bits?user_id=$portrait_user_id\"></a>
<p>
Name: <a href=[im_url_stub]/users/view?user_id=$portrait_user_id>$name</a>
<br>Office: <a href=[im_url_stub]/offices/view?group_id=$office_id>$office</a>
[util_decode $bio "" "" "<br>Biography: $bio"]
[util_decode $skills "" "" "<br>Special skills: $skills"]
"

}

ad_proc im_restricted_access {} {Returns an access denied message and blows out 2 levels} {
    ad_return_forbidden "Access denied" "You must be an authorized user of the [ad_system_name] intranet to see this page. You can <a href=/register/index?return_url=[ad_urlencode [im_url_with_query]]>login</a> as someone else if you like."
    return -code return
}

ad_proc im_allow_authorized_or_admin_only { group_id current_user_id } {Returns an error message if the specified user is not able to administer the specified group or the user is not a site-wide/intranet administrator} {

    set user_admin_p [im_can_user_administer_group $group_id $current_user_id]

    if { ! $user_admin_p } {
	# We let all authorized users have full administrative control
	set user_admin_p [im_user_is_authorized_p $current_user_id]
    }

    if { $user_admin_p == 0 } {
	im_restricted_access
	return
    }
}

ad_proc im_groups_url {{-section "" -group_id "" -short_name ""}} {Sets up the proper url for the /groups stuff in acs} {
    if { [empty_string_p $group_id] && [empty_string_p $short_name] } {
	ad_return_error "Missing group_id and short_name" "We need either the short name or the group id to set up the url for the /groups directory"
    }
    if { [empty_string_p $short_name] } {
	set short_name [db_string groups_get_short_name \
		"select short_name from user_groups where group_id=:group_id"]
    }
    if { ![empty_string_p $section] } {
	set section "/$section"
    }
    return "/groups/[ad_urlencode $short_name]$section"
}

ad_proc im_customer_group_id_from_user {} {Sets group_id and short_name in the calling environment of the first customer_id this proc finds for the logged in user} {
    uplevel {
	set customer_group_id [im_customer_group_id]
	set local_user_id [ad_get_user_id]
	if { ![db_0or1row customer_name_from_user \
		"select g.group_id, g.short_name
		   from user_groups g, user_group_map ugm 
		  where g.group_id=ugm.group_id
		    and g.parent_group_id = :customer_group_id
		    and ugm.user_id=:local_user_id
             	    and rownum<2"] } {
            # Define the variables so we won't have errors using them
	    set group_id ""
	    set short_name ""
	}
    }
}

ad_proc im_user_information { user_id } {
Returns an html string of all the intranet applicable information for one 
user. This information can be used in the shared community member page, for 
example, to give intranet users a better understanding of what other people
are doing in the site.
} {

    set caller_id [ad_get_user_id]
    
    # is this user an employee?
    set user_employee_p [im_user_is_employee_p $user_id]

    set return_url [im_url_with_query]

    # we need a backup copy
    set user_id_copy $user_id

    # If we're looking at our own entry, we can modify some information
    if {$caller_id == $user_id} {
	set looking_at_self_p 1
    } else {
	set looking_at_self_p 0
    }

    # can the user make administrative changes to this page
    set user_admin_p [im_is_user_site_wide_or_intranet_admin $caller_id]

    if { ![db_0or1row employee_info \
	    "select u.*, uc.*, info.*,
                    ((sysdate - info.first_experience)/365) as years_experience
               from users u, users_contact uc, im_employee_info info
              where u.user_id = :user_id 
                and u.user_id = uc.user_id(+)
                and u.user_id = info.user_id(+)"] } {
        # Can't find the user		    
	ad_return_error "Error" "User doesn't exist"
	ad_script_abort
    }
    # get the user portrait
    set portrait_p [db_0or1row portrait_info "
       select portrait_id,
	      portrait_upload_date,
	      portrait_client_file_name
         from general_portraits
	where on_what_id = :user_id
	  and upper(on_which_table) = 'USERS'
	  and approved_p = 't'
	  and portrait_primary_p = 't'
    "]

    # just in case user_id was set to null in the last query
    set user_id $user_id_copy
    set office_group_id [im_office_group_id]

    set sql "select ug.group_name, ug.group_id
    from user_groups ug, im_offices o
    where ad_group_member_p ( :user_id, ug.group_id ) = 't'
    and o.group_id=ug.group_id
    and ug.parent_group_id=:office_group_id
    order by lower(ug.group_name)"

    set offices ""
    set number_offices 0
    db_foreach offices_user_belongs_to $sql {
	incr number_offices
	if { ![empty_string_p $offices] } {
	    append offices ", "
	}
	append offices "  <a href=[im_url_stub]/offices/view?[export_url_vars group_id]>$group_name</A>"
    }

    set page_content "<ul>\n"

    if [exists_and_not_null job_title] {
	append page_content "<LI>Job title: $job_title\n"
    }

    if { $number_offices > 0 } {
	append page_content "  <li>[util_decode $number_offices 1 Office Offices]: $offices\n"
	if { $looking_at_self_p } {
	    append page_content "(<a href=[im_url_stub]/users/office-update?[export_url_vars user_id]>manage</a>)\n"
	}
    } elseif { $user_employee_p } {
	if { $looking_at_self_p } {
	    append page_content "  <li>Office: <a href=[im_url_stub]/users/add-to-office?[export_url_vars user_id return_url]>Add yourself to an office</a>\n"
	} elseif { $user_admin_p } {
	    append page_content "  <li>Office: <a href=[im_url_stub]/users/add-to-office?[export_url_vars user_id return_url]>Add this user to an office</a>\n"
	}
    }

    if [exists_and_not_null years_experience] {
	append page_content "<LI>Job experience: [format %3.1f $years_experience] years\n"
    }

    if { $user_employee_p } {
	# Let's offer a link to the people this person manages, if s/he manages somebody
	db_1row subordinates_for_user \
		"select decode(count(*),0,0,1) as number_subordinates
                   from im_employees_active 
                  where supervisor_id=:user_id"
	if { $number_subordinates == 0 } {
	    append page_content "  <li> <a href=[im_url_stub]/employees/org-chart>Org chart</a>: This user does not supervise any employees.\n"
	} else {
	    append page_content "  <li> <a href=[im_url_stub]/employees/org-chart>Org chart</a>: <a href=[im_url_stub]/employees/org-chart?starting_user_id=$user_id>View the org chart</a> starting with this employee\n"
	}

	set number_superiors [db_string employee_count_superiors \
		"select max(level)-1 
                   from im_employee_info
                  start with user_id = :user_id
                connect by user_id = PRIOR supervisor_id"]
	if { [empty_string_p $number_superiors] } {
	    set number_superiors 0
	}

	# Let's also offer a link to see to whom this person reports
	if { $number_superiors > 0 } {
	    append page_content "  <li> <a href=[im_url_stub]/employees/org-chart-chain?[export_url_vars user_id]>View chain of command</a> starting with this employee\n"
	}
    }	

    if { [exists_and_not_null portrait_upload_date] } {
	if { $looking_at_self_p } {
	    append page_content "<p><li><a href=/pvt/portrait/index?[export_url_vars return_url]>Portrait</A>\n"
	} else {
	    append page_content "<p><li><a href=/shared/portrait?[export_url_vars user_id]>Portrait</A>\n"
	}
    } elseif { $looking_at_self_p } {
	append page_content "<p><li>Show everyone else at [ad_system_name] how great looking you are:  <a href=/pvt/portrait/upload?[export_url_vars return_url]>upload a portrait</a>"
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
	set return_url [im_url_with_query]
	if { $user_employee_p } {
	    append page_content "<p>(<A HREF=[im_url_stub]/users/info-update?[export_url_vars return_url]>edit</A>)\n"
	} else {
	    # Non-employees should just use the public update page
	    append page_content "<p>(<A HREF=/pvt/basic-info-update?[export_url_vars return_url]>edit</A>)\n"
	}
    }

    if { $user_employee_p } {
	append page_content "
    <p><i>Current projects:</i><ul>\n"

	set projects_html ""

	set sql \
	    "select user_group_name_from_id(group_id) as project_name, parent_id,
                    decode(parent_id,null,null,user_group_name_from_id(parent_id)) as parent_project_name,
                    group_id as project_id
               from im_projects p
              where p.project_status_id in (select project_status_id
                                              from im_project_status 
                                             where project_status='Open' 
                                                or project_status='Future')
                and ad_group_member_p ( :user_id, p.group_id ) = 't'
            connect by prior group_id=parent_id
              start with parent_id is null"

	set projects_html ""
	db_foreach current_projects_for_employee $sql {
	    append projects_html "  <li> "
	    if { ![empty_string_p $parent_id] } {
		append projects_html "<a href=[im_url_stub]/projects/view?group_id=$parent_id>$parent_project_name</a> : "
	    }
	    append projects_html "<a href=[im_url_stub]/projects/view?group_id=$project_id>$project_name</a>\n"
	}
	if { [empty_string_p $projects_html] } {
	    set projects_html "  <li><i>None</i>\n"
	}

	append page_content "
	$projects_html
    </ul>
    "

	set sql "select start_date as unformatted_start_date, to_char(start_date, 'Mon DD, YYYY') as start_date, to_char(end_date,'Mon DD, YYYY') as end_date, contact_info, initcap(vacation_type) as vacation_type, vacation_id,
    description from user_vacations where user_id = :user_id 
    and (start_date >= to_date(sysdate,'YYYY-MM-DD') or
    (start_date <= to_date(sysdate,'YYYY-MM-DD') and end_date >= to_date(sysdate,'YYYY-MM-DD')))
    order by unformatted_start_date asc"

	set office_absences ""
	db_foreach vacations_for_employee $sql {
	    if { [empty_string_p $vacation_type] } {
		set vacation_type "Vacation"
	    }
	    append office_absences "  <li><b>$vacation_type</b>: $start_date - $end_date, <br>$description<br>
	    Contact info: $contact_info"
	    
	    if { $looking_at_self_p || $user_admin_p } {
		append office_absences "<br><a href=[im_url]/absences/edit?[export_url_vars vacation_id]>edit</a>"
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

	if { [ad_parameter TrackHours intranet 0] && [im_user_is_employee_p $user_id] } {
	    append page_content "
	<p><a href=[im_url]/hours/index?on_which_table=im_projects&[export_url_vars user_id]>View this person's work log</a>
	</ul>
	"
        }

    }

    append page_content "</ul>\n"

    # Append a list of all the user's groups
    set sql "select ug.group_id, ug.group_name 
               from user_groups ug
              where ad_group_member_p ( :user_id, ug.group_id ) = 't'
              order by lower(group_name)"
    set groups ""
    db_foreach groups_user_belong_to $sql {
	append groups "  <li> $group_name\n"
    }
    if { ![empty_string_p $groups] } {
	append page_content "<p><b>Groups to which this user belongs</b><ul>\n$groups</ul>\n"
    }

    # don't sign it with the publisher's email address!
    return $page_content
}

ad_proc im_yes_no_table { yes_action no_action { var_list [list] } { yes_button " Yes " } {no_button " No "} } "Returns a 2 column table with 2 actions - one for yes and one for no. All the variables in var_list are exported into the to forms. If you want to change the text of either the yes or no button, you can ser yes_button or no_button respectively." {
    set hidden_vars ""
    foreach varname $var_list {
        if { [eval uplevel {info exists $varname}] } {
            upvar $varname value
            if { ![empty_string_p $value] } {
		append hidden_vars "<input type=hidden name=$varname value=\"[ad_quotehtml $value]\">\n"
            }
        }
    }
    return "
<table>
  <tr>
    <td><form method=post action=\"[ad_quotehtml $yes_action]\">
        $hidden_vars
        <input type=submit name=operation value=\"[ad_quotehtml $yes_button]\">
        </form>
    </td>
    <td><form method=get action=\"[ad_quotehtml $no_action]\">
        $hidden_vars
        <input type=submit name=operation value=\"[ad_quotehtml $no_button]\">
        </form>
    </td>
  </tr>
</table>
"
}

ad_proc im_spam_multi_group_exists_clause { 
    bind
    group_id_list 
} {
    returns a portion of an sql where clause that begins
    with " and exists..." and includes all the groups in the 
    comma separated list of group ids (group_id_list)
} {
    set criteria [list]
    set ctr 0
    foreach group_id [split $group_id_list ","] {
	set group_id [string trim $group_id]
	if { [empty_string_p $group_id] } {
	    continue
	}
	set var_name im_spam_multi_group_$ctr
	ns_set put $bind $var_name $group_id
	lappend criteria "ad_group_member_p(u.user_id, :$var_name) = 't'"
	incr ctr
    }
    if { [llength $criteria] > 0 } {
	return " and [join $criteria "\n and "] "
    } else {
	return ""
    }
}

ad_proc im_spam_number_users { group_id_list {all_or_any "all"} } {
    Returns the number of users that belong to all/any of the groups in 
    the comma separated list of group ids (group_id_list)
} {
    set bind_vars [ns_set create]
    set ctr 0
    # Bind all the group ids... There's probably a much better way to
    # do this, but I can't think of one right now
    set criteria [list]
    foreach group_id [split $group_id_list ","] {
	incr ctr
	ns_set put $bind_vars group_id_$ctr $group_id
	lappend criteria "(select 1 from user_group_map ugm where u.user_id=ugm.user_id and ugm.group_id=:group_id_${ctr})"
    }
    if { $ctr == 0 } {
	# What else can we return?
	return 0
    }
    if { "$all_or_any" == "all" } {
	set ugm_clause " and exists [join $criteria " and exists "] "
    } else {
	set ugm_clause " or exists [join $criteria " or exists "] "
    }
    set value [db_string number_users_in_groups \
	    "select count(distinct u.user_id)
               from users_active u, user_group_map ugm
              where u.user_id=ugm.user_id $ugm_clause" -bind $bind_vars]
    ns_set free $bind_vars
    return $value
}

ad_proc im_group_scope_url { group_id return_url module_url {user_belongs_to_group_p ""} } {
    Creates a url for a group scoped module. If the current user is
    not in the group for the module, we redirect first to a page to
    explain that the user must be in the group to access the scoping
    functionality. 
 } {
    
    if { [regexp {\?} $module_url] } {
	set url "$module_url&"
    } else {
	set url "$module_url?"
    }
    append url "scope=group&[export_url_vars group_id return_url]"
    if { ![empty_string_p $user_belongs_to_group_p] && $user_belongs_to_group_p } {
	set in_group_p 1
    } else {
	set in_group_p [ad_user_group_member $group_id [ad_get_user_id]]
    }
    if { $in_group_p } {
	return $url
    }
    set continue_url $url
    set cancel_url $return_url
    return "[im_url_stub]/group-member-option?[export_url_vars group_id continue_url cancel_url]"
}

ad_proc im_hours_for_user { user_id { html_p t } { number_days 7 } } {
    Returns a string in html or text format describing the number of
    hours the specified user logged and what s/he noted as work done in
    those hours.  
} {
    set sql "select g.group_id, g.group_name, nvl(h.note,'no notes') as note, 
		    to_char( day, 'Dy, MM/DD/YYYY' ) as nice_day, h.hours
               from im_hours h, user_groups g
	      where g.group_id = h.on_what_id
     	        and h.on_which_table = 'im_projects'
                and h.day >= sysdate - :number_days
                and user_id=:user_id
              order by lower(g.group_name), day"
    
    set last_id -1
    set pcount 0
    set num_hours 0
    set html_string ""
    set text_string ""

    db_foreach hours_for_user $sql {
	if { $last_id != $group_id } {
	    set last_id $group_id
	    if { $pcount > 0 } {
		append html_string "</ul>\n"
		append text_string "\n"
	    }
	    append html_string " <li><b>$group_name</b>\n<ul>\n"
	    append text_string "$group_name\n"
	    set pcount 1
	}
	append html_string "   <li>$nice_day ($hours [util_decode $hours 1 "hour" "hours"]): &nbsp; <i>$note</i>\n"
	append text_string "  * $nice_day ($hours [util_decode $hours 1 "hour" "hours"]): $note\n"
	set num_hours [expr $num_hours + $hours]
    }

    # Let's get the punctuation right on days
    set number_days_string "$number_days [util_decode $number_days 1 "day" "days"]"

    if { $num_hours == 0 } {
	set text_string "No hours logged in the last $number_days_string."
	set html_string "<b>$text_string</b>"
    } else {
	if { $pcount > 0 } {
	    append html_string "</ul>\n"
	    append text_string "\n"
	}
        set html_string "<b>$num_hours [util_decode $num_hours 1 hour hours] logged in the last $number_days_string:</b>
<ul>$html_string</ul>"
        set text_string "$num_hours [util_decode $num_hours 1 hour hours] logged in the last $number_days_string:
$text_string"
    }
        
    return [util_decode $html_p "t" $html_string $text_string]
}

# --------------------------------------------------------------------------------
# functions for printing the org chart
# --------------------------------------------------------------------------------

ad_proc im_print_employee {person rowspan} "print function for org chart" {
    set user_id [fst $person]
    set employee_name [snd $person]
    set currently_employed_p [thd $person]

# Removed job title display
#    set job_title [lindex $person 3]

    if { $currently_employed_p == "t" } {

# Removed job title display
#	if { $rowspan>=2 } {
#	    return "<a href=/intranet/users/view?[export_url_vars user_id]>$employee_name</a><br><i>$job_title</i>\n"
#	} else {
	    return "<a href=/intranet/users/view?[export_url_vars user_id]>$employee_name</a><br>\n"
#	}
    } else {
	return "<i>Position Vacant</i>"
    }
}

ad_proc im_prune_org_chart {tree} "deletes all leaves where currently_employed_p is set to vacant position" {
    set result [list [head $tree]]
    # First, recursively process the sub-trees.
    foreach subtree [tail $tree] {
	set new_subtree [im_prune_org_chart $subtree]
	if { ![null_p $new_subtree] } {
	    lappend result $new_subtree
	}
    }
    # Now, delete vacant leaves.
    # We also delete vacant inner nodes that have only one child.
    # 1. if the tree only consists of one vacant node
    #    -> return an empty tree
    # 2. if the tree has a vacant root and only one child
    #    -> return the child 
    # 3. otherwise
    #    -> return the tree 
    if { [thd [head $result]] == "f" } {
	switch [llength $result] {
	    1       { return [list] }
	    2       { return [snd $result] }
	    default { return $result }
	}
    } else {
	return $result
    }
}

ad_proc im_url_with_query { { url "" } } {Returns the current url (or the one specified) with all queries correctly attached} {
    if { [empty_string_p $url] } {
	set url [ns_conn url]
    }
    set query [export_ns_set_vars url]
    if { ![empty_string_p $query] } {
	append url "?$query"
    }
    return $url
}

ad_proc im_header { { page_title "" } { extra_stuff_for_document_head "" } } {
    The standard intranet header
} {
    if { [empty_string_p $page_title] } {
	set page_title [ad_partner_upvar page_title]
    }
    set context_bar [ad_partner_upvar context_bar]
    set page_focus [ad_partner_upvar page_focus]
    if { [empty_string_p $extra_stuff_for_document_head] } {
	set extra_stuff_for_document_head [ad_partner_upvar extra_stuff_for_document_head]
    }
    set graphic [ad_parameter DefaultGraphic intranet ""]
    if { ![empty_string_p $graphic] } {
	set graphic "<img src=\"$graphic\"><br>"
    }
    return "
[ad_header -focus $page_focus $page_title $extra_stuff_for_document_head]
$graphic
<font size=4><b>$page_title</b></font>
<br><font size=2>$context_bar</font>
<hr>

"
}

ad_proc im_footer {} {
    Standard intranet footer. We use a different call to let people easily enhance
    the intranet footer without disturbing the rest of acs
} {
    return [ad_footer]
}

ad_proc im_return_template {} {
    Wrapper that adds page contents to header and footer 
} {
    uplevel { 
	return "  
[im_header]
[value_if_exists page_body]
[value_if_exists page_content]
[im_footer]
"
    }

}


ad_proc im_memoize_list { { -bind "" } statement_name sql_query { force 0 } {also_memoize_as ""} } {
    Allows you to memoize database queries without having to grab a db
    handle first. If the query you specified is not in the cache, this
    proc grabs a db handle, and memoizes a list, separated by $divider
    inside the cache, of the results. Your calling proc can then process
    this list as normally. 
} {

    ns_share im_memoized_lists

    set str ""
    set divider "\253"

    if { [info exists im_memoized_lists($sql_query)] } {
	set str $im_memoized_lists($sql_query)
    } else {
	# ns_log Notice "Memoizing: $sql_query"
	if { [catch {set db_data [db_list_of_lists $statement_name $sql_query -bind $bind]} err_msg] } {
	    # If there was an error, let's log a nice error message that includes 
	    # the statement we executed and any bind variables
	    ns_log error "im_memoize_list: Error executing db_list_of_lists $statement_name \"$sql_query\" -bind \"$bind\""
	    if { [empty_string_p $bind] } {
		set bind_string ""
	    } else {
		set bind_string [NsSettoTclString $bind]
		ns_log error "im_memoize_list: Bind Variables: $bind_string"
	    }
	    error "im_memoize_list: Error executing db_list_of_lists $statement_name \"$sql_query\" -bind \"$bind\"\n\n$bind_string\n\n$err_msg\n\n"
	}
	foreach row $db_data {
	    foreach col $row {
		if { ![empty_string_p $str] } {
		    append str $divider
		}
		append str $col
	    }
	}
	set im_memoized_lists($sql_query) $str
    }
    if { ![empty_string_p $also_memoize_as] } {
	set im_memoized_lists($also_memoize_as) $str
    }
    return [split $str $divider]
}

ad_proc im_memoize_one { { -bind "" } statement_name sql { force 0 } { also_memoize_as "" } } { 
    wrapper for im_memoize_list that returns the first value from
    the sql query.
} {
    set result_list [im_memoize_list -bind $bind $statement_name $sql $force $also_memoize_as]
    if { [llength $result_list] > 0 } {
	return [lindex $result_list 0]
    }
    return ""
}

ad_proc im_maybe_insert_link { previous_page next_page { divider " - " } } {
    Formats prev and next links
} {
    set link ""
    if { ![empty_string_p $previous_page] } {
	append link "$previous_page"
    }
    if { ![empty_string_p $next_page] } {
	if { ![empty_string_p $link] } {
	    append link $divider
	}
	append link "$next_page"
    }
    return $link
}

ad_proc im_default_nav_header { previous_page next_page { search_action "" } { search_target "" } { submit_text "Go" } } {
    Returns appropriately punctuated links for previous and next pages. 
} {
    set link [im_maybe_insert_link $previous_page $next_page " | "]
    if { [empty_string_p $search_action] } {
	return $link
    }
    return "<form name=im_header_form method=get action=\"[ad_quotehtml $search_action]\">
<input type=hidden name=target [export_form_value search_target]>
<input type=text name=keywords [export_form_value search_default]>
<input type=submit value=\"[ad_quotehtml $submit_text]\">
[util_decode $link "" "" "<br>$link"]
</form>
"
}

ad_proc im_employees_initial_list {} {
    Memoizes and returns a list where the ith element is the user's
    last initital and the i+1st element is the number of employees
    with that initial
} {
    return [im_memoize_list select_employees_initials \
	    "select im_first_letter_default_to_a(u.last_name), count(*)
               from im_employees_active u
              group by im_first_letter_default_to_a(u.last_name)"]
}

ad_proc im_groups_initial_list { parent_group_id } {
    Memoizes and returns a list where the ith element is the first
    initital of the group name and the i+1st element is the number of 
    groups with that initial. Only includes groups whose parent_group_id
    is as specified.
} {
    set bind_vars [ns_set create]
    ns_set put $bind_vars parent_group_id $parent_group_id
    return [im_memoize_list -bind $bind_vars select_groups_initials \
	    "select im_first_letter_default_to_a(ug.group_name), count(*)
               from user_groups ug
              where ug.parent_group_id = :parent_group_id
              group by im_first_letter_default_to_a(ug.group_name)"]
}

ad_proc im_all_letters { } {returns a list of all A-Z letters in uppercase} {
    return [list A B C D E F G H I J K L M N O P Q R S T U V W X Y Z] 
}

ad_proc im_employees_alpha_bar { { letter "" } { vars_to_ignore "" } } {
    Returns the alpha bar for employees.
} {
    return [im_alpha_nav_bar $letter [im_employees_initial_list] $vars_to_ignore]
}

ad_proc im_groups_alpha_bar { parent_group_id { letter "" } { vars_to_ignore "" } } {
    Returns the alpha bar for user_groups whose parent group is as
    specified.  
} {
    return [im_alpha_nav_bar $letter [im_groups_initial_list $parent_group_id] $vars_to_ignore]
}

ad_proc im_alpha_nav_bar { letter initial_list {vars_to_ignore ""} } {
    Returns an A-Z bar with greyed out letters not
    in initial_list and bolds "letter". Note that this proc returns the
    empty string if there are fewer than NumberResultsPerPage records.
    
    inital_list is a list where the ith element is a letter and the i+1st
    letter is the number of times that letter appears.  
} {

    set min_records [ad_parameter NumberResultsPerPage intranet 50]
    # Let's run through and make sure we have enough records
    set num_records 0
    foreach { l count } $initial_list {
	incr num_records $count
    }
    if { $num_records < $min_records } {
	return ""
    }

    set url "[ns_conn url]?"
    set vars_to_ignore_list [list "letter"]
    foreach v $vars_to_ignore { 
	lappend vars_to_ignore_list $v
    }

    set query_args [export_ns_set_vars url $vars_to_ignore_list]
    if { ![empty_string_p $query_args] } {
	append url "$query_args&"
    }
    
    set html_list [list]
    foreach l [im_all_letters] {
	if { [lsearch -exact $initial_list $l] == -1 } {
	    # This means no user has this initial
	    lappend html_list "<font color=gray>$l</font>"
	} elseif { [string compare $l $letter] == 0 } {
	    lappend html_list "<b>$l</b>"
	} else {
	    lappend html_list "<a href=${url}letter=$l>$l</a>"
	}
    }
    if { [empty_string_p $letter] || [string compare $letter "all"] == 0 } {
	lappend html_list "<b>All</b>"
    } else {
	lappend html_list "<a href=${url}letter=all>All</a>"
    }
    if { [string compare $letter "scroll"] == 0 } {
	lappend html_list "<b>Scroll</b>"
    } else {
	lappend html_list "<a href=${url}letter=scroll>Scroll</a>"
    }
    return [join $html_list " | "]
}

ad_proc im_select_row_range {sql firstrow lastrow} {
    a tcl proc curtisg wrote to return a sql query that will only 
    contain rows firstrow - lastrow
} {
    return "select im_select_row_range_y.*
              from (select im_select_row_range_x.*, rownum fake_rownum 
                      from ($sql) im_select_row_range_x
                     where rownum <= $lastrow) im_select_row_range_y
             where fake_rownum >= $firstrow"
}

ad_proc im_force_user_to_log_hours { conn args why } {
    If a user is not on vacation and has not logged hours since
    yesterday midnight, we ask them to log hours before using the
    intranet. Sets state in session so user is only asked once 
    per session.
} {
    if { ![im_enabled_p] || ![ad_parameter TrackHours intranet 0] } {
	# intranet or hours-logging not turned on. Do nothing
	return filter_ok
    } 
    
    set last_prompted_time [ad_get_client_property intranet user_asked_to_log_hours_p]

    if { ![empty_string_p $last_prompted_time] && \
	    $last_prompted_time > [expr [ns_time] - 60*60*24] } {
	# We have already asked the user in this session, within the last 24 hours, 
	# to log their hours
	return filter_ok
    }
    # Let's see if the user has logged hours since 
    # yesterday midnight. 
    # 

    set user_id [ad_get_user_id]
    if { $user_id == 0 } {
	# This can't happen on standard acs installs since intranet is protected
	# But we check any way to prevent bugs on other installations
	return filter_ok
    }

    db_1row hours_logged_by_user \
	    "select decode(count(*),0,0,1) as logged_hours_p, 
                    to_char(sysdate - 1,'J') as julian_date
	       from im_hours h, users u
	      where h.user_id = :user_id
	        and h.user_id = u.user_id
	        and h.hours > 0
	        and h.day <= sysdate
	        and (u.on_vacation_until >= sysdate
    	             or h.day >= trunc(u.second_to_last_visit-1))"

    # Let's make a note that the user has been prompted 
    # to update hours or is okay. This saves us the database 
    # hit next time. 
    ad_set_client_property -persistent f intranet user_asked_to_log_hours_p [ns_time]

    if { $logged_hours_p } {
	# The user has either logged their hours or
	# is on vacation right now
	return filter_ok
    }

    # Pull up the screen to log hours for yesterday
    set return_url [im_url_with_query]
    ad_returnredirect "[im_url_stub]/hours/ae?[export_url_vars return_url julian_date]"
    return filter_return
}

ad_proc im_force_user_to_enter_project_report { conn args why } {
    If a user is not on vacation and is late with their project
    report, Send them to a screen to enter that project report.
    Sets state in session so user is only asked once per session.
} {
    if { ![im_enabled_p] } {
	# intranet or hours-logging not turned on. Do nothing
	return filter_ok
    } 
    
    set last_prompted_time [ad_get_client_property intranet user_asked_to_fill_out_project_reports_p]

    if { ![empty_string_p $last_prompted_time] && \
	    $last_prompted_time > [expr [ns_time] - 60*60*24] } {
	# We have already asked the user in this session, within the last 24 hours, 
	# to enter their missing project report
	return filter_ok
    }

    set user_id [ad_get_user_id]
    if { $user_id == 0 } {
	# This can't happen on standard acs installs since intranet is protected
	# But we check any way to prevent bugs on other installations
	return filter_ok
    }

    # Let's make a note that the user has been prompted 
    # to enter project reports. This saves us the database 
    # hit next time. 
    ad_set_client_property -persistent f intranet user_asked_to_fill_out_project_reports_p [ns_time]

    # build up a list of all the project reports we need to fill out
    # We'll use this as a stack to go through all project reports 
    #  until we're out of places to go
    set groups_list [list]
    
    # first check if the user is no vacation
    set user_on_vacation [db_string user_is_on_vacation \
	    "select nvl(u.on_vacation_until,sysdate-1) - sysdate from users u where u.user_id=:user_id"]

    if { $user_on_vacation > 0 } {
	# we're on vacation right now. no need to log hours
	return filter_ok
    }

    set group_name_id_list [im_list_late_project_report_groups_for_user $user_id]

    if { [llength $group_name_id_list] == 0 } {
	# no late project reports
	return filter_ok
    }

    # We have late project reports - let's build up a fancy return_url
    
    # first the current url - the last place we want to go
    set return_url [im_url_with_query]
    foreach { group_name group_id } $group_name_id_list {
	set return_url "[im_url_stub]/projects/report-add?[export_url_vars group_id return_url]"
    }
    
    ad_returnredirect $return_url
    return filter_return
}

ad_proc im_email_people_in_group { group_id role from subject message } {
    Emails the message to all people in the group who are acting in
    the specified role
} {
    # Until we use roles, we only accept the following:
    set second_group_id ""
    switch $role {
	"employees" { set second_group_id [im_employee_group_id] }
	"customers" { set second_group_id [im_customer_group_id] }
    }
	
    set criteria [list]
    if { [empty_string_p $second_group_id] } {
	if { [string compare $role "all"] != 0 } {
	    return ""
adde	}
    } else {
	lappend criteria "ad_group_member_p(u.user_id, :second_group_id) = 't'"
    }
    lappend criteria "ad_group_member_p(u.user_id, :group_id) = 't'"
    
    set where_clause [join $criteria "\n        and "]

    set email_list [db_list active_users_list_emails \
	    "select email from users_active u where $where_clause"]

    # Convert html stuff to text
    # Conversion fails for forwarded emails... leave it our for now
    # set message [ad_html_to_text $message]
    foreach email $email_list {
	catch { ns_sendmail $email $from $subject $message }
    }
    
}

ad_proc im_bboard_restrict_access_to_group args {
    BBoard security hack
    Restricts access to a bboard if it has a group_id set for the
    specified topic_id or msg_id
} {

    if { ![im_enabled_p] || ![ad_parameter EnableIntranetBBoardSecurityFiltersP intranet 0] } {
	# no need to check anything in this case!
	return filter_ok
    }

    set form [ns_getform]
    
    if { [empty_string_p $form] } {
	# The form is empty - presumably we're not accessing any 
	# bboard topic or message!
	return filter_ok
    }
    
    # 3 ways to identify a message - see if we have any of them!
    set topic_id [ns_set get $form topic_id]
    set msg_id [ns_set get $form msg_id]
    set refers_to [ns_set get $form refers_to]

    if { ![regexp {^[0-9]+$} $topic_id] } {
        # topic_id is not an integer
        set topic_id ""
    }
    
    if { [empty_string_p $topic_id] && [empty_string_p $msg_id]  && [empty_string_p $refers_to] } {
        # Don't have a msg_id or topic_id or refers_to - can't do anything... 
        # Grant access by default
        return filter_ok
    }

    if { [empty_string_p $topic_id] } {
        # Get the topic id from whatever identifier we have
        if { [empty_string_p $msg_id] } {
            set msg_id $refers_to
        }
        set topic_id [db_string bboard_topic_from_id \
                "select topic_id from bboard where msg_id=:msg_id" -default ""]
        if { [empty_string_p $topic_id] } {
            # still no way to determine the topic, let bboard handle it
            return filter_ok
        }
    }
    
    set user_id [ad_get_user_id]
    set has_access_p 0

    if { $user_id > 0 } {
	db_1row user_can_access_bboard_topic \
		"select decode(count(*),0,0,1) as has_access_p
	           from bboard_topics t
                  where t.topic_id = :topic_id
                  and (t.group_id is null
	               or ad_group_member_p(:user_id, t.group_id) = 't')"

	if { $has_access_p == 0 } {
	    # Check if this is an intranet authorized user - they
	    # get to see everything!
	    set has_access_p [im_user_is_authorized_p $user_id]
	}
    } elseif {$user_id == 0} {
        # the user isnt loged in
	db_1row user_can_access_this_bboard_topic \
		"select decode(count(*),0,0,1) as has_access_p
	           from bboard_topics t
                  where t.topic_id = :topic_id
                    and t.group_id is null"
    }

    if { $has_access_p } {
	return filter_ok
    } 
    ad_return_forbidden "Access denied" "This section of the bboard is restricted. You must either be a member of the group who owns this topic or an authorized user of the [ad_system_name] intranet. You can <a href=/register/index?return_url=[ad_urlencode [im_url_with_query]]>login</a> as someone else if you like."
    return filter_return	
}


ad_proc im_hours_verify_user_id { { user_id "" } } {
    Returns either the specified user_id or the currently logged in
    user's user_id. If user_id is null, throws an error unless the
    currently logged in user is a site-wide or intranet administrator.
} {

    # Let's make sure the 
    set caller_id [ad_verify_and_get_user_id]
    if { [empty_string_p $user_id] || $caller_id == $user_id } {
        return $caller_id
    } 
    # Only administrators can edit someone else's hours
    if { [im_is_user_site_wide_or_intranet_admin $caller_id] } {
        return $user_id
    }

    # return an error since the logged in user is not editing his/her own hours
    ad_return_error "You can't edit someone else's hours" "It looks like you're trying to edit someone else's hours. Unforunately, you're not authorized to do so. You can edit your <a href=time-entry?[export_ns_set_vars url [list user_id]]>own hours</a> if you like"
    return -code return
}


# --------------------------------------------------------------------------------
# Added by Mark Dettinger <mdettinger@arsdigita.com>
# --------------------------------------------------------------------------------

ad_proc num_days_in_month {month {year 1999}} {
    Returns the number of days in a given month.
    The month can be specified as 1-12, Jan-Dec or January-December.
    The year argument is optional. It's only needed for February.
    If no year is given, it defaults to 1999 (a non-leap-year).
} {
    if { [elem_p $month [month_list]] } { 
        set month [expr [lsearch [month_list] $month]+1]
    }
    if { [elem_p $month [long_month_list]] } { 
        set month [expr [lsearch [long_month_list] $month]+1]
    }
    switch $month {
        1 { return 31 }
        2 { return [expr [leap_year_p $year]?29:28] }
        3 { return 31 }
        4 { return 30 }
        5 { return 31 }
        6 { return 30 }
        7 { return 31 }
        8 { return 31 }
        9 { return 30 }
        10 { return 31 }
        11 { return 30 }
        12 { return 31 }
        default { error "Month $month invalid. Must be in range 1 - 12." }
    }
}

ad_proc absence_list_for_user_and_time_period {user_id first_julian_date last_julian_date} {
    For a given user and time period, this proc
    returns a list of elements where each element 
    corresponds to one day and describes its
    "work/vacation type".
} {
    # Select all vacation periods that have at least one day
    # in the given time period.
    set sql "
        select to_char(start_date,'J') as start_date,
               to_char(end_date,'J') as end_date,
               vacation_type
        from user_vacations
        where user_id = :user_id
        and   start_date <= to_date(:last_julian_date,'J')
        and   end_date   >= to_date(:first_julian_date,'J')
    "
    # Initialize array with "work" elements.
    for {set i $first_julian_date} {$i<=$last_julian_date} {incr i} {
        set vacation($i) work
    }
    # Process vacation periods and modify array accordingly.
    db_foreach vacation_period $sql {
        for {set i [max $start_date $first_julian_date]} {$i<=[min $end_date $last_julian_date]} {incr i } {
            set vacation($i) $vacation_type
        }
    }
    # Return the relevant part of the array as a list.
    set result [list]
    for {set i $first_julian_date} {$i<=$last_julian_date} {incr i} {
        lappend result $vacation($i)
    }
    return $result
}


## MJS 8/2
ad_proc ad_build_url args { 

    Proc for building an entire url.
    To replace export_url_vars, used in a similar manner

    The main difference is that this proc accepts the stub
    as the first argument, and prepends either a ? or &
    to each variable as necessary.  If the first argument
    is null, then the returned value is equivalent to 
    that which is returned by export_url_vars.

    Usage: build_url stubvar argvar1 argvar2 argvar3 ...
    OR     build_url "literalstub" argvar1 argvar2 argvar3 ...
    
    Usage backwards-compatible with export_url_vars:

    build_url "" argvar1 argvar2 argvar3 ...

} {

    set stubvar [lindex $args 0]
    set varlist [lrange $args 1 end]

    set bind_char "?"

    ## the stub - can be a variable name or a value
    if { [empty_string_p $stubvar] } {
	
	## export_url_vars compatibility mode

	set stub ""
	set bind_char ""
	
    } else {
	
	upvar 1 $stubvar stub
	
	if { ![info exists stub] } { 
	
	    ## literal stub mode

	    set stub $stubvar
	}
	    
	if { [regexp {\?} $stub match] } {
	    set bind_char "&"
	}
    }
    
    ## the vars - expect only variable names  
    foreach var $varlist { 
	
	upvar 1 $var value 
	
	if { [info exists value] } {
	    lappend params "$var=[ns_urlencode $value]" 
	} 
    } 

    return "$stub$bind_char[join $params "&"]"
} 


## MJS 8/2
ad_proc im_validate_and_set_category_type {} {

    Used as security for category-list, category-add, and category-edit and edit-2
    in employees/admin.  

    We use these generalized pages to manage several subsets of the categories table,
    but to avoid url hackery that would access other subsets, we define the allowed
    subsets here.

    category_html is a plural pretty-name that is both displayed on the page and passed
    in the url.  category_type is its corresponding column data in the categories table.

    Ideally, these subsets should become their own tables and this proc should be 
    obsoleted.

} {

    upvar 1 category_html got_category_html

    switch $got_category_html {

	"Hiring Sources" { uplevel { set category_type "Intranet Hiring Source"} }
	"Previous Positions" { uplevel { set category_type "Intranet Prior Experience"} }
	"Job Titles" { uplevel { set category_type "Intranet Job Title"} }
	
	default { 
	    
	    ad_return_complaint 1 "<LI><I>$got_category_html</I> is not a valid category"
	    
	}
    }

    return 1
}


ad_proc im_email_aliases { short_name } {
    Returns an html string describing the intranet email alias system,
    if it's turned on.  
} {
    set domain [ad_parameter EmailDomain intranet ""]
    if { [empty_string_p $domain] || ![ad_parameter LogEmailToGroupsP intranet 0] } {
	# No email aliases set up
	return "  <li> Project short name: $short_name\n"
    } 
    set help_link "(<a href=[im_url_stub]/help/email-aliases?[export_url_vars short_name]&return_url=[ad_urlencode [im_url_with_query]]>help</a>)"
    if { [regexp { } $short_name] } {
	return "  <li> Email aliases - this group's short name, \"$short_name,\" cannot contain a space for email aliases to work $help_link\n"
    }

    return "
  <li> Email aliases $help_link:
       <ul> 
         <li> <a href=mailto:${short_name}@$domain>$short_name@$domain</a>
         <li> <a href=mailto:${short_name}-employees@$domain>${short_name}-employees@$domain</a>
         <li> <a href=mailto:${short_name}-customers@$domain>${short_name}-customers@$domain</a>
         <li> <a href=mailto:${short_name}-all@$domain>${short_name}-all@$domain</a>
       </ul>
"
}



ad_proc im_calendar_insert_or_update {
    -type
    -current_user_id
    -on_which_table:required
    -on_what_id:required
    -start_date:required
    -user_id:required
    -related_url:required
    -title:required
    -group_id
    -end_date
    -description
} {
    Sets defaults we use in the intranet and then calls
    cal_insert_repeating_item with the appropriate tags.  Note that in
    particular, group_id defaults to the employees group.
} {
    # If the calendar package is not enabled, this becomes a no-op
    if ![apm_package_enabled_p "calendar"] {
	return
    }
    if { ![exists_and_not_null type] } {
	set type "insert"
    }
    if { ![exists_and_not_null current_user_id] } {
	set current_user_id [ad_get_user_id]
    }
    if { ![exists_and_not_null end_date] } {
	set end_date $start_date
    }
    if { ![exists_and_not_null group_id] } {
	set group_id [im_employee_group_id]
    }
    if { ![info exists description] } {
	set description ""
    }

    if { [string compare $type "insert"] != 0 } {
	# Remove old instances so they'll be added below
	cal_delete_mapped_instances $on_which_table $on_what_id
    }
    
    cal_insert_repeating_item -on_which_table $on_which_table -on_what_id $on_what_id -start_date $start_date -end_date $end_date -creation_user $current_user_id -title $title -user_id $user_id -group_id $group_id -related_url_p "t" -related_url $related_url -editable_p "f" -description $description

}

