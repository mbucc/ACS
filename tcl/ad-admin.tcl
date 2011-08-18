# $Id: ad-admin.tcl,v 3.2 2000/03/02 20:45:16 davis Exp $
# ad-admin.tcl
#
# created by philg 11/18/98
#
# procedures used only in admin pages (mostly the user class stuff)
#

util_report_library_entry

proc_doc ad_administrator_p {db {user_id ""}} {Returns 1 if the user is part of the site-wide administration group. 0 otherwise.} {
    if [empty_string_p $user_id] {
	set user_id [ad_verify_and_get_user_id $db]
    }

    set ad_group_member_p [database_to_tcl_string $db "select ad_group_member_p($user_id, system_administrator_group_id) from dual"]

    return [ad_decode $ad_group_member_p "t" 1 0]
}

ns_share -init {set admin_administrator_filter_installed_p 0} admin_administrator_filter_installed_p

if { !$admin_administrator_filter_installed_p } {
    set admin_administrator_filter_installed_p 1
    ad_register_filter preauth GET "/admin/*" ad_restrict_to_administrator
    ns_log Notice "/tcl/ad-admin.tcl is restricting URLs matching \"/admin/*\" to administrator"
}

proc ad_restrict_to_administrator {conn args why} {
    set db [ns_db gethandle subquery]
    if { [ad_administrator_p $db] } {
	ns_db releasehandle $db
	return "filter_ok"
    } else {
	ns_db releasehandle $db
 	ad_return_error "You are not an administrator" "Sorry, but you must be logged on as a site wide administrator to talk to the admin pages.

<p>

Visit <a href=\"/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]\">/register/</a> to log in now.
"
 	# have AOLserver abort the thread
 	return "filter_return"
    }
}


# the proc below was added June 27, 1999, inspired by Malte Sussdorff (sussdorff@sussdorff.de)
proc_doc ad_ssl_available_p {} "Returns 1 if this AOLserver has the SSL module installed." {
    if { [ns_config ns/server/[ns_info server]/modules nsssl] != "" } {
	return 1
    } else {
	return 0
    }
}

ns_share -init {set admin_ssl_filters_installed_p 0} admin_ssl_filters_installed_p

if {!$admin_ssl_filters_installed_p && [ad_ssl_available_p]} {
    set admin_ssl_filters_installed_p 1
    # we'd like to use ad_parameter_all_values_as_list here but can't because 
    # it isn't defined until ad-defs.tcl
    set the_set [ns_configsection "ns/server/[ns_info server]/acs"]
    set filter_patterns [list]
    for {set i 0} {$i < [ns_set size $the_set]} {incr i} {
	if { [ns_set key $the_set $i] == "RestrictToSSL" } {
	    lappend filter_patterns [ns_set value $the_set $i]
	}
    }
    foreach pattern $filter_patterns {
	ad_register_filter preauth GET $pattern ad_restrict_to_https
	ns_log Notice "/tcl/ad-admin.tcl is restricting URLs matching \"$pattern\" to SSL"
    }
}

proc ad_restrict_to_https {conn args why} {
    if { [ns_conn driver] == "nsssl" } {
 	# we're happy; administrator is being safe and password
 	# can't be sniffed
 	return "filter_ok"
    } else {
 	ad_return_error "Please use HTTPS" "Sorry but you have to use HTTPS to talk to the admin pages."
 	# have AOLserver abort the thread
 	return "filter_return"
    }
}



proc_doc ad_approval_system_inuse_p {} "Returns 1 if the system is configured to use and approval system." {
    if {[ad_parameter RegistrationRequiresEmailVerification] && [ad_parameter RegistrationRequiresApprovalP] } {
	return 1
    } else {
	return 0
    }
}


proc ad_user_class_parameters {} {
    return [list category_id country_code usps_abbrev intranet_user_p group_id last_name_starts_with email_starts_with expensive user_state sex age_above_years age_below_years registration_during_month registration_before_days registration_after_days registration_after_date last_login_before_days last_login_after_days last_login_equals_days number_visits_below number_visits_above user_class_id sql_post_select crm_state curriculum_elements_completed]
}
 
proc_doc ad_user_class_description {selection} "Takes an ns_set of key/value pairs and produces a human-readable description of the class of users specified." {
    set db [ns_db gethandle subquery]
    set clauses [list]
    set pretty_description ""
    # because we named our arg "selection", we can use this magic
    # utility procedure to set everything as a local var 
    set_variables_after_query

    foreach criteria [ad_user_class_parameters] {
	if { [info exists $criteria] && ![empty_string_p [set $criteria]] } {
	    switch $criteria {
		"category_id" {
		    set pretty_category [database_to_tcl_string $db "select category from categories where category_id = $category_id"]
		    lappend clauses "said they were interested in $pretty_category"
		}
		"country_code" {
		    set pretty_country [database_to_tcl_string $db "select country_name from country_codes where iso = '$country_code'"]
		    lappend clauses "told us that they live in $pretty_country"
		}
		"usps_abbrev" {
		    set pretty_state [database_to_tcl_string $db "select state_name from states where usps_abbrev = '$usps_abbrev'"]
		    lappend clauses "told us that they live in $pretty_state"
		}
		"intranet_user_p" {
		    lappend clauses "are an employee"
		}
		"group_id" {
		    set group_name [database_to_tcl_string $db "select group_name from user_groups where group_id=$group_id"]
		    lappend clauses "are a member of $group_name"
		}
		"last_name_starts_with" {
		    lappend clauses "have a last name starting with $last_name_starts_with"
		}
		"email_starts_with" {
		    lappend clauses "have an email address starting with $email_starts_with"
		}	
		"expensive" {
		    lappend clauses "have accumulated unpaid charges of more than [ad_parameter ExpensiveThreshold "member-value"]"
		}
		"user_state" {
		    lappend clauses "have user state of $user_state"
		}
		"sex" {
		    lappend clauses "are $sex."
		}
		"age_above_years" {
		    lappend clauses "is older than $age_above_years years"
		}
		"age_below_years" {
		    lappend clauses "is younger than $age_below_years years"
		}
		"registration_during_month" {
		    set pretty_during_month [database_to_tcl_string $db "select to_char(to_date('$registration_during_month','YYYYMM'),'fmMonth YYYY') from dual"]
		    lappend clauses "registered during $pretty_during_month"
		}
		"registration_before_days" {
		    lappend clauses "registered over $registration_before_days days ago"
		}
		"registration_after_days" {
		    lappend clauses "registered in the last $registration_after_days days"
		}
		"registration_after_date" {
		    lappend clauses "registered on or after $registration_after_date"
		}
		"last_login_before_days" {
		    lappend clauses "have not visited the site in $last_login_before_days days"
		}
		"last_login_after_days" {
		    lappend clauses "have not visited the site in $last_login_after_days days"
		}
		"last_login_equals_days" {
		    if { $last_login_equals_days == 1 } {
			lappend clauses "visited the site exactly 1 day ago"
		    } else {
			lappend clauses "visited the site exactly $last_login_equals_days days ago"
		    }
		}
		"number_of_visits_below" {
		    lappend clauses "have visited less than $number_visits_below times"
		}
		"number_of_visits_above" {
		    lappend clauses "have visited more than $number_visits_above times"
		}
		"user_class_id" {
		    set pretty_class_name [database_to_tcl_string $db "select name from user_classes where user_class_id = $user_class_id"]
		    lappend clauses "are in the user class $pretty_class_name"
		}
		"sql_post_select" {
		    lappend clauses "are returned by \"<i>select users(*) from $sql_post_select</i>"
		}
		"crm_state" {
		    lappend clauses "are in the customer state \"$crm_state\""
		}
		"curriculum_elements_completed" {
		    if { $curriculum_elements_completed == 1 } {
			lappend clauses "who have completed exactly $curriculum_elements_completed curriculum element"
		    } else {
			lappend clauses "who have completed exactly $curriculum_elements_completed curriculum elements"
		    }
		}
	    }
	    if { [info exists combine_method] && $combine_method == "or" } {
		set pretty_description [join $clauses " or "]
	    } else {
		set pretty_description [join $clauses " and "]
	    }

	}
    }
    ns_db releasehandle $db
    return $pretty_description
}



proc_doc ad_user_class_query {selection} "Takes an ns_set of key/value pairs and produces a query for the class of users specified (one user per row returned)." {
    # we might need this 
    set where_clauses [list]
    set join_clauses [list]
    set group_clauses [list]
    set having_clauses [list]
    set tables [list users]
    # because we named our arg "selection", we can use this magic
    # utility procedure to set everything as a local var 
    set_variables_after_query

    # if we are using a user_class, just get the info

    if { [info exists count_only_p] && $count_only_p } {
	set select_list "count(users.user_id)"
    } else {
	# Get all the non-LOB columns.
	set user_columns [list]
	set db [ns_db gethandle subquery]
	foreach column [GetColumnNames $db "users"] {
	    if { $column != "portrait" && $column != "portrait_thumbnail" } {
		lappend user_columns "users.$column"
	    }
	}
	ns_db releasehandle $db
	set select_list [join $user_columns ", "]
    }
    if { [info exists include_contact_p] && $include_contact_p} {
	append select_list ", user_contact_summary(users.user_id) as contact_summary"
    }
    if { [info exists include_demographics_p] && $include_demographics_p} {
	append select_list ", user_demographics_summary(users.user_id) as demographics_summary"
    }
    
    if { [info exists user_class_id] && ![empty_string_p $user_class_id] } {
	set db [ns_db gethandle subquery]
	set sql_post_select [database_to_tcl_string $db "select sql_post_select
	from user_classes where user_class_id = $user_class_id"]
	ns_db releasehandle $db
	return "select $select_list $sql_post_select"
    }
    
    if { [info exists sql_post_select] && ![empty_string_p $sql_post_select] } {
	return "select $select_list $sql_post_select"
    }

    foreach criteria [ad_user_class_parameters] {
	if { [info exists $criteria] && ![empty_string_p [set $criteria]] } {
	    switch $criteria {
		"category_id" {
		    if {[lsearch $tables "users_interests"] == -1 } {
		    lappend tables "users_interests"
			lappend join_clauses "users.user_id = users_interests.user_id"
		    }
		    lappend where_clauses "users_interests.category_id = $category_id"
		}
		"country_code" {
		    if {[lsearch $tables "users_contact"] == -1 } {
			lappend tables "users_contact"
			lappend join_clauses "users.user_id = users_contact.user_id"
		    }
		    lappend where_clauses "users_contact.ha_country_code = '$country_code'"
		}
		"usps_abbrev" {
		    if {[lsearch $tables "users_contact"] == -1 } {
			lappend tables "users_contact"
			lappend join_clauses "users.user_id = users_contact.user_id"
		    }
		    lappend where_clauses "(users_contact.ha_state = '$usps_abbrev' and (users_contact.ha_country_code is null or users_contact.ha_country_code = 'us'))"
		}
		"intranet_user_p" {
		    if {$intranet_user_p == "t" && [lsearch $tables "intranet_users"] == -1 } {
			lappend tables "intranet_users"
			lappend join_clauses "users.user_id = intranet_users.user_id"
		    }
		}
		"group_id" {
 		    #if {[lsearch $tables "users_group_map"] == -1 } {
 			#lappend tables "user_group_map"
 			#lappend join_clauses "users.user_id = user_group_map.user_id"
 		    #}
 		    #lappend where_clauses "user_group_map.group_id = $group_id"
		    lappend where_clauses "ad_group_member_p(users.user_id, $group_id) = 't'"
		}
		
		"last_name_starts_with" {
		    lappend where_clauses "upper(users.last_name) like upper('[DoubleApos $last_name_starts_with]%')"
		}
		"email_starts_with" {
		    lappend where_clauses "upper(users.email) like upper('[DoubleApos $email_starts_with]%')"
		}
		"expensive" {
		    if { [info exists count_only_p] && $count_only_p } {
			lappend where_clauses "[ad_parameter ExpensiveThreshold "member-value"] < (select sum(amount) from users_charges where users_charges.user_id = users.user_id)"
		    } else {
			if {[lsearch $tables "user_charges"] == -1 } {
			    lappend tables "users_charges"
			    lappend join_clauses "users.user_id = users_charges.user_id"
			}
			# we are going to be selecting users.* in general, so
			# we must group by all the columns in users (can't 
			# GROUP BY USERS.* in Oracle, sadly)
			set db [ns_db gethandle subquery]
			foreach column [GetColumnNames $db "users"] {
			    # can't group by a BLOB column.
			    if { $column != "portrait" && $column != "portrait_thumbnail" } {
				lappend group_clauses "users.$column"
			    }
			}
			ns_db releasehandle $db
			lappend having_clauses "sum(users_charges.amount) > [ad_parameter ExpensiveThreshold "member-value"]"
			# only the ones where they haven't paid
			lappend where_clauses "users_charges.order_id is null"
		    }
		}
		"user_state" {
		    lappend where_clauses "users.user_state = '$user_state'"
		}
		"sex" {
		    if {[lsearch $tables "users_demographics"] == -1 } {
			lappend tables "users_demographics"
			lappend join_clauses "users.user_id = users_demographics.user_id"
		    }
		    lappend where_clauses "users_demographics.sex = '$sex'"
		}
		"age_below_years" {
		    if {[lsearch $tables "users_demographics"] == -1 } {
			lappend tables "users_demographics"
			lappend join_clauses "users.user_id = users_demographics.user_id"
		    }
		    lappend where_clauses "users_demographics.birthdate > sysdate - ($age_below_years * 365.25)"
		}
		"age_above_years" {
		    if {[lsearch $tables "users_demographics"] == -1 } {
			lappend tables "users_demographics"
			lappend join_clauses "users.user_id = users_demographics.user_id"
		    }
		    lappend where_clauses "users_demographics.birthdate < sysdate - ($age_above_years * 365.25)"
		}
		"registration_during_month" {
		    lappend where_clauses "to_char(users.registration_date,'YYYYMM') = '$registration_during_month'"
		}
		"registration_before_days" {
		    lappend where_clauses "users.registration_date < sysdate - $registration_before_days"
		}
		"registration_after_days" {
		    lappend where_clauses "users.registration_date > sysdate - $registration_after_days"
		}
		"registration_after_date" {
		    lappend where_clauses "users.registration_date > '$registration_after_date'"
		}
		"last_login_before_days" {
		    lappend where_clauses "users.last_visit < sysdate - $last_login_before_days"
		}
		"last_login_after_days" {
		    lappend where_clauses "users.last_visit > sysdate - $last_login_after_days"
		}
		"last_login_equals_days" {
		    lappend where_clauses "round(sysdate-last_visit) = $last_login_equals_days"
		}
		"number_visits_below" {
		    lappend where_clauses "users.n_sessions < $number_visits_below"
		}
		"number_visits_above" {
		    lappend where_clauses "users.n_sessions > $number_visits_above"
		}
		"crm_state" {
		    lappend where_clauses "users.crm_state = '$crm_state'"
		}
		"curriculum_elements_completed" {
		    lappend where_clauses "$curriculum_elements_completed = (select count(*) from user_curriculum_map ucm where ucm.user_id = users.user_id and ucm.curriculum_element_id in (select curriculum_element_id from curriculum))"
		}
	    }
	}
    }
    #stuff related to the query itself
    
    if { [info exists combine_method] && $combine_method == "or" } {
	set complete_where [join $where_clauses " or "]
    } else {
	set complete_where [join $where_clauses " and "]
    }
    

    if { [info exists include_accumulated_charges_p] && $include_accumulated_charges_p && (![info exists count_only_p] || !$count_only_p) } {
	# we're looking for expensive users and not just counting them
	append select_list ", sum(users_charges.amount) as accumulated_charges"
    }
    if { [llength $join_clauses] == 0 } {
	set final_query "select $select_list
	from [join $tables ", "]"
	if ![empty_string_p $complete_where] {
	    append final_query "\nwhere $complete_where"
	}
    } else {
	# we're joining at 
	set final_query "select $select_list
	from [join $tables ", "]
	where [join $join_clauses "\nand "]"
	if ![empty_string_p $complete_where] {
	    append final_query "\n and ($complete_where)"
	}
    }
    if { [llength $group_clauses] > 0 } {
	append final_query "\ngroup by [join $group_clauses ", "]"
    }
    if { [llength $having_clauses] > 0 } {
	append final_query "\nhaving [join $having_clauses " and "]"
    }
    return $final_query
}


    
proc_doc ad_user_class_query_count_only {selection} "Takes an ns_set of key/value pairs and produces a query that will compute the number of users in the class specified." {
    set new_set [ns_set copy $selection]
    ns_set put $new_set count_only_p 1
    return [ad_user_class_query $new_set]
}


proc_doc ad_registration_finite_state_machine_admin_links {user_state user_id} "Returns the admininistation links to change the user's state in the user_state finite state machine." {
    set user_finite_state_links [list]
    switch $user_state {
	"authorized" { 
	    lappend user_finite_state_links "<a target=approve href=delete.tcl?[export_url_vars user_id]>ban or delete</a>"
	}
	"deleted" {
	    lappend user_finite_state_links "<a target=approve href=undelete.tcl?[export_url_vars user_id]>undelete</a>"
	    lappend user_finite_state_links "<a target=approve href=reject.tcl?[export_url_vars user_id]>ban</a>"
	}
	"need_email_verification_and_admin_approv" {
	    lappend user_finite_state_links "<a  target=approve href=approve.tcl?[export_url_vars user_id]>approve</a>"
	    lappend user_finite_state_links "<a  target=approve href=reject.tcl?[export_url_vars user_id]>reject</a>"
	}
	"need_admin_approv" {
	    lappend user_finite_state_links "<a target=approve href=approve.tcl?[export_url_vars user_id]>approve</a>"
	    lappend user_finite_state_links "<a target=approve href=reject.tcl?[export_url_vars user_id]>reject</a>"
	}
	"need_email_verification" {
            lappend user_finite_state_links "<a target=approve href=approve-email.tcl?[export_url_vars user_id]>approve email</a>"
	    lappend user_finite_state_links "<a target=approve href=reject.tcl?[export_url_vars user_id]>reject</a>"
	}
	"rejected" {
	    lappend user_finite_state_links "<a  target=approve href=approve.tcl?[export_url_vars user_id]>approve</a>"
	}
	"banned" {
	    lappend user_finite_state_links "<a target=approve href=unban.tcl?[export_url_vars user_id]>unban</a>"
	}
    }
    return $user_finite_state_links
}    

util_report_successful_library_load
