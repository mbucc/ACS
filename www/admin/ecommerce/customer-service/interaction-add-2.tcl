# $Id: interaction-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:38 carsten Exp $
set_the_usual_form_variables
# If this is coming from interaction-add.tcl:
# open_date, interaction_type, interaction_type_other, interaction_originator, and
# (a) If it's an unknown customer: first_names, last_name, email, postal_code,
#     other_id_info
# (b) If it's a known customer: c_user_identification_id and issue_id

# If this is coming from interaction-add-3.tcl (meaning that they are adding
# another action to this interaction):
# interaction_id, c_user_identification_id ("c" stands for "confirmed" meaning
# that they've been through interaction-add-3.tcl and now they cannot change
# the user_identification_id)

# Possibly:
# return_to_issue

# the customer service rep must be logged on

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

if { ![info exists interaction_id] } {

    # put together open_date, and do error checking
    
    set exception_count 0
    set exception_text ""
    set form [ns_getform]
    
    # ns_dbformvalue $form open_date date open_date will give an error
    # message if the day of the month is 08 or 09 (this octal number problem
    # we've had in other places).  So I'll have to trim the leading zeros
    # from ColValue.open%5fdate.day and stick the new value into the $form
    # ns_set.
    
    set "ColValue.open%5fdate.day" [string trimleft [set ColValue.open%5fdate.day] "0"]
    ns_set update $form "ColValue.open%5fdate.day" [set ColValue.open%5fdate.day]
    
    if [catch  { ns_dbformvalue $form open_date datetime open_date} errmsg ] {
	incr exception_count
	append exception_text "<li>The date or time was specified in the wrong format.  The date should be in the format Month DD YYYY.  The time should be in the format HH:MI:SS (seconds are optional), where HH is 01-12, MI is 00-59 and SS is 00-59.\n"
    } elseif { [string length [set ColValue.open%5fdate.year]] != 4 } {
	incr exception_count
	append exception_text "<li>The year needs to contain 4 digits.\n"
    }

    if { ![info exists interaction_type] || [empty_string_p $interaction_type] } {
	incr exception_count
	append exception_text "<li>You forgot to specify the method of inquiry (phone/email/etc.).\n"
    } elseif { $interaction_type == "other" && (![info exists interaction_type_other] || [empty_string_p $interaction_type_other]) } {
	incr exception_count
	append exception_text "<li>You forgot to fill in the text box for Other.\n"
    } elseif { $interaction_type != "other" && ([info exists interaction_type_other] && ![empty_string_p $interaction_type_other]) } {
	incr exception_count
	append exception_text "<li>You selected \"Inquired via: [string toupper [string index $interaction_type 0]][string range $interaction_type 1 [expr [string length $interaction_type] -1]]\", but you also filled in something in the \"If Other, specify\" field.  This is inconsistent.\n"
    }
    
    if { $exception_count > 0 } {
	ad_return_complaint $exception_count $exception_text
	return
    }

    # done error checking
}

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

# Have to generate action_id
# action_id will be used by the next page to tell whether the user pushed
# submit twice
# interaction_id will not be generated until the next page (if it doesn't
# exist) so that I can use the fact of its existence or lack of existence
# to create this page's UI

set action_id [database_to_tcl_string $db "select ec_action_id_sequence.nextval from dual"]

ReturnHeaders

ns_write "[ad_admin_header "One Issue"]
<h2>One Issue</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "One Issue (part of New Interaction)"]

<hr>
A customer may discuss several issues during the course of one interaction.  Please
enter the information about only one issue below:

<form method=post action=interaction-add-3.tcl>
[export_form_vars interaction_id c_user_identification_id action_id open_date interaction_type interaction_type_other interaction_originator first_names last_name email postal_code other_id_info return_to_issue]

<table>
"

if { [info exists c_user_identification_id] } {
    ns_write "<tr>
    <td>Customer:</td>
    <td>[ec_user_identification_summary $db $c_user_identification_id "t"]"

    if { [info exists postal_code] } {
	ns_write "<br>
	[ec_location_based_on_zip_code $db $postal_code]
	"
    }


    ns_write "</td>
    </tr>
    "
}

if { ![info exists issue_id] } {
    ns_write "<tr>
    <td>Issue ID:</td>
    <td><input type=text size=4 name=issue_id>
    If this is a new issue, please leave this blank (a new Issue ID will be generated)</td>
    </tr>
    <tr>
    <td>Order ID:</td>
    <td><input type=text size=7 name=order_id>
    Fill this in if this inquiry is about a specific order.
    </td>
    </tr>
    <tr>
    <td>Issue Type: (leave blank if based on an existing issue):</td>
    <td>[ec_issue_type_widget $db]</td>
    </tr>
    "
} else {
    set order_id [database_to_tcl_string $db "select order_id from ec_customer_service_issues where issue_id=$issue_id"]
    set issue_type_list [database_to_tcl_list $db "select issue_type from ec_cs_issue_type_map where issue_id=$issue_id"]

    ns_write "<tr>
    <td>Issue ID:</td>
    <td>$issue_id[export_form_vars issue_id]</td>
    </tr>
    <tr>
    <td>Order ID:</td>
    <td>[ec_decode $order_id "" "none" $order_id]</td>
    </tr>
    <tr>
    <td>Issue Type</td>
    <td>[join $issue_type_list ", "]</td>
    </tr>
    "
}
ns_write "<tr>
<td>Details:</td>
<td><textarea wrap name=action_details rows=6 cols=45></textarea></td>
</tr>
<tr>
<td>Information used to respond to inquiry:</td>
<td>[ec_info_used_widget $db]</td>
</tr>
<tr>
<td>If follow-up is required, please specify:</td>
<td><textarea wrap name=follow_up_required rows=2 cols=45></textarea></td>
</tr>
<tr>
<td>Close this issue?</td>
<td>
<input type=radio name=close_issue_p value=\"f\" checked>No (Issue requires follow-up)
<input type=radio name=close_issue_p value=\"t\">Yes (Issue is resolved)
</td>
</tr>
</table>
"

if { ![info exists c_user_identification_id] } {
    ns_write "
    <p>
    
    <b>Customer identification:</b>
    
    <p>
    
    Here's what we could determine about the customer given the information you typed
    into the previous form:
    <ul>
    "
    
    set positively_identified_p 0
    
    # see if we can find their city/state from the zip code
    
    set location [ec_location_based_on_zip_code $db $postal_code]

    if { ![empty_string_p $location] } {
	ns_write "<li>They live in $location.\n"
    }

    
    # I'll be setting variables d_user_id, d_user_identification_id, d_first_names, etc.,
    # based on the user info they typed into the last form.  "d" stands for "determined",
    # meaning that I determined it, as opposed to it being something that they typed in
    
    # if their email address was filled in, see if they're a registered user
    if { ![empty_string_p $email] } {
	set selection [ns_db 0or1row $db "select first_names as d_first_names, last_name as d_last_name, user_id as d_user_id from users where upper(email) = '[string toupper $email]'"]
	
	if { ![empty_string_p $selection] } {
	    set_variables_after_query
	}
	
	if { [info exists d_user_id] } {
	    ns_write "<li>This is a registered user of the system: <a target=user_window href=\"/admin/users/one.tcl?user_id=$d_user_id\">$d_first_names $d_last_name</a>.
	    [export_form_vars d_user_id]"
	    set positively_identified_p 1
	}
	
    }
    
    if { !$positively_identified_p } {
	# then keep trying to identify them
	
	if { ![empty_string_p $first_names] || ![empty_string_p $last_name] } {
	    if { ![empty_string_p $first_names] && ![empty_string_p $last_name] } {
		set selection [ns_db select $db "select user_id as d_user_id from users where upper(first_names)='[DoubleApos [string toupper $first_names]]' and upper(last_name)='[DoubleApos [string toupper $last_name]]'"]
		while { [ns_db getrow $db $selection] } {
		    set_variables_after_query
		    ns_write "<li>This may be the registered user <a target=user_window href=\"/admin/users/one.tcl?user_id=$d_user_id\">$first_names $last_name</a> (check here <input type=checkbox name=d_user_id value=$d_user_id> if this is correct).\n"
		}
	    } elseif { ![empty_string_p $first_names] } {
		set selection [ns_db select $db "select user_id as d_user_id, last_name as d_last_name from users where upper(first_names)='[DoubleApos [string toupper $first_names]]'"]
		
		while { [ns_db getrow $db $selection] } {
		    set_variables_after_query
		    ns_write "<li>This may be the registered user <a target=user_window href=\"/admin/users/one.tcl?user_id=$d_user_id\">$first_names $d_last_name</a> (check here <input type=checkbox name=d_user_id value=$d_user_id> if this is correct).\n"
		}
		
	    } elseif { ![empty_string_p $last_name] } {
		set selection [ns_db select $db "select user_id as d_user_id, first_names as d_first_names from users where upper(last_name)='[DoubleApos [string toupper $last_name]]'"]
		
		while { [ns_db getrow $db $selection] } {
		    set_variables_after_query
		    ns_write "<li>This may be the registered user <a target=user_window href=\"/admin/users/one.tcl?user_id=$d_user_id\">$d_first_names $last_name</a> (check here <input type=checkbox name=d_user_id value=$d_user_id> if this is correct).\n"
		}
		
	    }
	}

	# also see if they might be a non-user who
	# has had an interaction before
	
	set already_selected_user_identification_id_list [list]
	if { ![empty_string_p $email] } {
	    set selection [ns_db select $db "select user_identification_id as d_user_identification_id from ec_user_identification where upper(email)='[DoubleApos [string toupper $email]]' and user_id is null"]
	    
	    while { [ns_db getrow $db $selection] } {
		set_variables_after_query
		ns_write "<li>This may be the non-registered person who has had a previous interaction with us: [ec_user_identification_summary $db_sub $d_user_identification_id "t"] (check here <input type=checkbox name=d_user_identification_id value=$d_user_identification_id> if this is correct)."
		lappend already_selected_user_identification_id_list $d_user_identification_id
	    }
	}
	
	set additional_and_clause ""
	if { [llength $already_selected_user_identification_id_list] > 0 } {
	    set additional_and_clause "and user_identification_id not in ([join $already_selected_user_identification_id_list ", "])"
	}
	
	if { ![empty_string_p $first_names] || ![empty_string_p $last_name] } {
	    if { ![empty_string_p $first_names] && ![empty_string_p $last_name] } {
		set selection [ns_db select $db "select user_identification_id as d_user_identification_id from ec_user_identification where upper(first_names)='[DoubleApos [string toupper $first_names]]' and upper(last_name)='[DoubleApos [string toupper $last_name]]' and user_id is null $additional_and_clause"]
	    } elseif { ![empty_string_p $first_names] } {
		set selection [ns_db select $db "select user_identification_id as d_user_identification_id from ec_user_identification where upper(first_names)='[DoubleApos [string toupper $first_names]]' and user_id is null $additional_and_clause"]
	    } elseif { ![empty_string_p $last_name] } {
		set selection [ns_db select $db "select user_identification_id as d_user_identification_id from ec_user_identification where upper(last_name)='[DoubleApos [string toupper $last_name]]' and user_id is null $additional_and_clause"]
	    }
	    
	    while { [ns_db getrow $db $selection] } {
		set_variables_after_query
		ns_write "<li>This may be the non-registered person who has had a previous interaction with us: [ec_user_identification_summary $db_sub $d_user_identification_id "t"] (check here <input type=checkbox name=d_user_identification_id value=$d_user_identification_id> if this is correct)."
		lappend already_selected_user_identification_id_list $d_user_identification_id
	    }
	}
	
	if { [llength $already_selected_user_identification_id_list] > 0 } {
	    set additional_and_clause "and user_identification_id not in ([join $already_selected_user_identification_id_list ", "])"
	}
	
	if { ![empty_string_p $other_id_info] } {
	    set selection [ns_db select $db "select user_identification_id as d_user_identification_id from ec_user_identification where other_id_info like '%[DoubleApos $other_id_info]%' $additional_and_clause"]
	    
	    while { [ns_db getrow $db $selection] } {
		set_variables_after_query
		ns_write "<li>This may be the non-registered person who has had a previous interaction with us: [ec_user_identification_summary $db_sub $d_user_identification_id "t"] (check here <input type=checkbox name=d_user_identification_id value=$d_user_identification_id> if this is correct)."
		lappend already_selected_user_identification_id_list $d_user_identification_id
	    }
	    
	}
	
	if { [llength $already_selected_user_identification_id_list] > 0 } {
	    set additional_and_clause "and user_identification_id not in ([join $already_selected_user_identification_id_list ", "])"
	}
	
	if { ![empty_string_p $postal_code] } {
	    set selection [ns_db select $db "select user_identification_id as d_user_identification_id from ec_user_identification where postal_code='[DoubleApos $postal_code]' $additional_and_clause"]
	    
	    while { [ns_db getrow $db $selection] } {
		set_variables_after_query
		ns_write "<li>This may be the non-registered person who has had a previous interaction with us: [ec_user_identification_summary $db_sub $d_user_identification_id "t"] (check here <input type=checkbox name=d_user_identification_id value=$d_user_identification_id> if this is correct)."
		lappend already_selected_user_identification_id_list $d_user_identification_id
	    }
	}
    }
    ns_write "</ul>
    <p>
    "
}

ns_write "<center>
<input type=submit name=submit value=\"Interaction Complete\">
<input type=submit name=submit value=\"Enter Another Issue as part of this Interaction\">
</center>

[ad_admin_footer]
"