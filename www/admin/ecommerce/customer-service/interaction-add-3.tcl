# $Id: interaction-add-3.tcl,v 3.0.4.1 2000/04/28 15:08:38 carsten Exp $
set_the_usual_form_variables
# Always:
# action_id, submit,
# issue_id, action_details, 
# info_used (select multiple), follow_up_required,
# close_issue_p

# If this is the first issue in this interaction:
# open_date, interaction_type, interaction_type_other, interaction_originator,
# first_names, last_name, email, postal_code, other_id_info
# possibly d_user_id or d_user_identification_id (shouldn't have both)

# If this is NOT the first issue in this interaction:
# interaction_id, c_user_identification_id, possibly postal_code

# If not coming from issue.tcl originally:
# order_id, issue_type (select multiple)

# Possibly:
# return_to_issue

set db [ns_db gethandle]

# doubleclick protection:
if { [database_to_tcl_string $db "select count(*) from ec_customer_service_actions where action_id=$action_id"] > 0 } {
    if { $submit == "Interaction Complete" } {
	ad_returnredirect interaction-add.tcl
    } else {
	# I have to use the action_id to figure out user_identification_id
	# and interaction_id so that I can pass them to interaction-add-2.tcl
	set selection [ns_db 0or1row $db "select i.user_identification_id as c_user_identification_id, a.interaction_id
	from ec_customer_service_actions a, ec_customer_serv_interactions i
	where i.interaction_id=a.interaction_id
	and a.action_id=$action_id"]
	set_variables_after_query
	ad_returnredirect "interaction-add-2.tcl?[export_url_vars interaction_id postal_code c_user_identification_id]"
    }
    return
}


# the customer service rep must be logged on

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# error checking
# what matters for the logic of the customer service system:
# 1. that we don't have more than one d_user_id or d_user_identification_id
#    (it's ok to have zero -- then a new user_identification_id will be generated,
#     unless c_user_identification_id exists)
# 2. if this is based on a previous issue_id, then issue_id must be valid and
#    issue ownership must be consistent
# 3. if this is based on a previous order, then order_id must be valid and 
#    order ownership must be consistent

set exception_count 0
set exception_text ""

# first some little checks on the input data

# issue_id and order_id should be numbers and action_details should be non-empty

if { [regexp "\[^0-9\]+" $issue_id] } {
    incr exception_count
    append exception_text "<li>The issue ID should be numeric.\n"
}

if { [info exists order_id] && [regexp "\[^0-9\]+" $order_id] } {
    incr exception_count
    append exception_text "<li>The order ID should be numeric.\n"
}

if { [empty_string_p $action_details] } {
    incr exception_count
    append exception_text "<li>You forgot to enter any details."
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# now for the painful checks

# only do this check for new interactions
if { ![info exists interaction_id] } {
    # 1. d_user_id and d_user_identification_id
    # d_user_id and d_user_identification_id come from checkboxes, so I have to
    # loop through $form to find all values
    
    set form [ns_getform]
    set form_size [ns_set size $form]
    set form_counter 0
    
    set d_user_id_list [list]
    set d_user_identification_id_list [list]
    while { $form_counter < $form_size} {
	set form_key [ns_set key $form $form_counter]
	if { $form_key == "d_user_id" || $form_key == "d_user_identification_id" } {
	    lappend ${form_key}_list [ns_set value $form $form_counter]
	}
	incr form_counter
    }
    
    if { [expr [llength $d_user_id_list] + [llength $d_user_identification_id_list] ] > 1 } {
	incr exception_count
	append exception_text "<li>You selected more than one user.  Please select at most one.\n"
    }

    # Don't even go on to check #2 if this first requirement isn't fulfilled
    if { $exception_count > 0 } {
	ad_return_complaint $exception_count $exception_text
	return
    }
}

# 2. consistent issue ownership

# If it's the first time through, give them the chance of matching up a 
# user with the interaction based on issue_id or order_id.
# Otherwise, the user_identification_id is set, so they will just be
# given an error message.
if { ![empty_string_p $issue_id] } {
    # see who this issue belongs to
    set selection [ns_db 0or1row $db "select u.user_id as issue_user_id, u.user_identification_id as issue_user_identification_id
    from ec_user_identification u, ec_customer_service_issues i
    where u.user_identification_id = i.user_identification_id
    and i.issue_id=$issue_id"]
    if { [empty_string_p $selection] } {
	ad_return_complaint 1 "<li>The issue ID that you specified is invalid.  Please go back and check the issue ID you entered.  If this is a new issue, please leave the issue ID blank.\n"
	return
    }
    set_variables_after_query

    if { ![info exists c_user_identification_id] } {
	# if the issue has a user_id associated with it and d_user_id doesn't exist or match
	# the associated user_id, then give them a message with the chance to make them match
	if { ![empty_string_p $issue_user_id] } {
	    if { ![info exists d_user_id] || [string compare $d_user_id $issue_user_id] != 0 } {
		ReturnHeaders
		ns_write "[ad_admin_header "User Doesn't Match Issue"]
		<h2>User Doesn't Match Issue</h2>
		[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "New Interaction"]
		
		<hr>
		Issue ID $issue_id belongs to the registered user <a href=\"/admin/users/one.tcl?user_id=$issue_user_id\">[database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$issue_user_id"]</a>.
		
		<p>
		
		However, you haven't selected that user as the customer involved in this interaction.
		
		<p>
		
		Would you like to make this user be the owner of this interaction?  (If not, push Back and fix the issue ID.)
		
		<form method=post action=interaction-add-3.tcl>
		[philg_hidden_input "d_user_id" $issue_user_id]
		[ec_export_entire_form_except d_user_id d_user_identification_id]
		<center>
		<input type=submit value=\"Yes\">
		</center>
		</form>
		
		[ad_admin_footer]
		"
		return
	    }
	} elseif { ![info exists d_user_identification_id] || [string compare $d_user_identification_id $issue_user_identification_id] != 0 } {
	    # if d_user_identification_id doesn't match the issue's user_identification_id, give
	    # them a message with the chance to make them match

	    ReturnHeaders
	    ns_write "[ad_admin_header "User Doesn't Match Issue"]
	    <h2>User Doesn't Match Issue</h2>
	    [ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "New Interaction"]
	    
	    <hr>
	    Issue ID $issue_id belongs to the the non-registered person who has had a previous interaction with us: [ec_user_identification_summary $db $issue_user_identification_id]
	    
	    <p>
	    
	    However, you haven't selected that user as the customer involved in this interaction.
	    
	    <p>
	    
	    Would you like to make this user be the owner of this interaction?  (If not, push Back and fix the issue ID.)
	    
	    <form method=post action=interaction-add-3.tcl>
	    [philg_hidden_input "d_user_identification_id" $issue_user_identification_id]
	    [ec_export_entire_form_except d_user_id d_user_identification_id]
	    <center>
	    <input type=submit value=\"Yes\">
	    </center>
	    </form>
	    
	    [ad_admin_footer]
	    "
	    return
	}

    } else {
	# non-new interaction; user_identification_id fixed
	# if the issue has a user_id, then the user_id associated with user_identification_id should match.
	# since it's possible for the same user to be represented by more than one user_identification_id,
	# we can't require that they match, although it is unfortunate if they don't (but it's too late to
	# do anything about it at this point -- I should make some way to combine user_identifications)
	if { ![empty_string_p $issue_user_id] } {
	    # find out the user_id associated with c_user_identification_id
	    set c_user_id [database_to_tcl_string $db "select user_id from ec_user_identification where user_identification_id=$c_user_identification_id"]
	    # if the c_user_id is null, they should be told about the option of matching up a user_id with
	    # user_identification_id
	    # otherwise, if the issue doesn't belong to them, they just get a plain error message
	    if { [empty_string_p $c_user_id] } {
		ad_return_complaint 1 "The issue ID you specified belongs to the registered user
		<a href=\"/admin/users/one.tcl?user_id=$issue_user_id\">[database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$issue_user_id"]</a>.  However, you haven't associated this interaction with any registered user.  You've associated it with the unregistered user [ec_user_identification_summary $db $c_user_identification_id].  If these are really the same user, match them up by clicking on the \"user info\" link and then you can reload this page without getting this error message." 
		return
	    } elseif { [string compare $c_user_id $issue_user_id] != 0 } {
		ad_return_complaint 1 "The issue ID you specified does not belong to the user you specified."
		return
	    }
	}
    }
}


# 3. consistent order ownership
if { [info exists order_id] && ![empty_string_p $order_id] } {
    # see who the order belongs to
    set selection [ns_db 0or1row $db "select user_id as order_user_id from ec_orders where order_id='$order_id'"]
    if { [empty_string_p $selection] } {
	ad_return_complaint 1 "<li>The order ID that you specified is invalid.  Please go back and check the order ID you entered.  If this issue is not about a specific order, please leave the order ID blank.\n"
	return
    }
    set_variables_after_query

    if { ![empty_string_p $order_user_id] } {

	if { ![info exists interaction_id] } {
	    if { ![info exists d_user_id] || [string compare $d_user_id $order_user_id] != 0 } {
		
		ReturnHeaders
		ns_write "[ad_admin_header "User Doesn't Match Order"]
		<h2>User Doesn't Match Order</h2>
		[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "New Interaction"]
		
		<hr>
		Order ID $order_id belongs to the registered user <a href=\"/admin/users/one.tcl?user_id=$order_user_id\">[database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id='$order_user_id'"]</a>.
		
		<p>
		
		However, you haven't selected that user as the customer involved in this interaction.
		
		<p>
		
		Would you like to make this user be the owner of this interaction?  (If not, push Back and fix the order ID.)
		
		<form method=post action=interaction-add-3.tcl>
		[philg_hidden_input "d_user_id" $order_user_id]
		[ec_export_entire_form_except d_user_id d_user_identification_id]
		<center>
		<input type=submit value=\"Yes\">
		</center>
		</form>
		
		[ad_admin_footer]
		"
		return
	    }
	} else {
	    # interaction_id exists
	    # find out the user_id associated with c_user_identification_id
	    set c_user_id [database_to_tcl_string $db "select user_id from ec_user_identification where user_identification_id=$c_user_identification_id"]
	    # if the c_user_id is null, they should be told about the option of matching up a user_id with
	    # user_identification_id
	    # otherwise, if the order doesn't belong to them, they just get a plain error message
	    if { [empty_string_p $c_user_id] } {
		ad_return_complaint 1 "The order ID you specified belongs to the registered user
		<a href=\"/admin/users/one.tcl?user_id=$order_user_id\">[database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id='$order_user_id'"]</a>.  However, you haven't associated this interaction with any registered user.  You've associated it with the unregistered user [ec_user_identification_summary $db $c_user_identification_id].  If these are really the same user, match them up by clicking on the \"user info\" link and then you can reload this page without getting this error message." 
		return
	    } elseif { [string compare $c_user_id $order_user_id] != 0 } {
		ad_return_complaint 1 "The order ID you specified does not belong to the user you specified."
		return
	    }
	
	}
    }
    # Otherwise, the order is in_basket (that's why it has no user_id associated with it).
    # If the user_identification_id has a user_id associated with it, we should
    # probably give them them opportunity of sticking that into the ec_orders
    # table
    # but maybe that's giving them too much power to mess things up, so I guess not
}

# done error checking
# deal w/select multiples

set form_counter 0

set issue_type_list [list]
set info_used_list [list]

while { $form_counter < $form_size} {
    set form_key [ns_set key $form $form_counter]
    if { $form_key == "issue_type" || $form_key == "info_used" } {
	set form_value [ns_set value $form $form_counter]
	if { ![empty_string_p $form_value] } {
	    lappend ${form_key}_list $form_value
	}
    }
    incr form_counter
}


if { [info exists interaction_id] } {
    # then the open_date didn't get passed along to this
    # script (but we need it for new customer service issues)
    set open_date [database_to_tcl_string $db "select to_char(interaction_date, 'YYYY-MM-DD HH24:MI:SS') as open_date from ec_customer_serv_interactions where interaction_id=$interaction_id"]
}



# create the sql string for inserting open_date
set date_string "to_date('$open_date','YYYY-MM-DD HH24:MI:SS')"

if { [info exists interaction_id] } {
    set create_new_interaction_p "f"
} else {
    set create_new_interaction_p "t"
}

ns_db dml $db "begin transaction"


# I. Have to generate:
#   1. interaction_id, unless it already exists
#   2. issue_id, unless it already exists

# interaction_id will either be a number or it will not exist
if { ![info exists interaction_id] } {
    set interaction_id [database_to_tcl_string $db "select ec_interaction_id_sequence.nextval from dual"]
}

# issue_id will either be a number or it will be the empty string
if { [empty_string_p $issue_id] } {
    set issue_id [database_to_tcl_string $db "select ec_issue_id_sequence.nextval from dual"]
    set create_new_issue_p "t"
} else {
    set create_new_issue_p "f"
}

# II. User identification (first time through):
#   1. If we have d_user_id, see if there's a user_identification with that user_id
#   2. Otherwise, see if we have d_user_identification_id
#   3. Otherwise, create a new user_identification_id

if { $create_new_interaction_p == "t" && ![info exists c_user_identification_id] } {
    if { [info exists d_user_id] } {
	set selection [ns_db select $db "select user_identification_id as uiid_to_insert from ec_user_identification where user_id=$d_user_id"]
	
	while { [ns_db getrow $db $selection] } {
	    set_variables_after_query
	    ns_db flush $db
	    break
	}
    } 
    
    if { ![info exists uiid_to_insert] } {
	
	if { [info exists d_user_identification_id] } {
	    set uiid_to_insert $d_user_identification_id
	} else {
	    set user_id_to_insert ""
	    if { [info exists d_user_id] } {
		set user_id_to_insert $d_user_id
	    }
	    set uiid_to_insert [database_to_tcl_string $db "select ec_user_ident_id_sequence.nextval from dual"]
	    ns_db dml $db "insert into ec_user_identification
	    (user_identification_id, user_id, email, first_names, last_name, postal_code, other_id_info)
	    values
	    ($uiid_to_insert, '$user_id_to_insert', '$QQemail','$QQfirst_names','$QQlast_name','$QQpostal_code','$QQother_id_info')
	    "
	}
    }
} else {
    set uiid_to_insert $c_user_identification_id
}


# III. Interaction (only if this is the first time through):
#   Have to insert into ec_customer_serv_interactions:
#   1. interaction_id
#   2. customer_service_rep
#   3. user_identification_id (= uiid_to_insert determined in II)
#   4. interaction_date (= open_date)
#   5. interaction_originator
#   6. interaction_type (=  interaction_type or interaction_type_other)

if { $create_new_interaction_p == "t" } {
    ns_db dml $db "insert into ec_customer_serv_interactions
    (interaction_id, customer_service_rep, user_identification_id, interaction_date, interaction_originator, interaction_type)
    values
    ($interaction_id, $customer_service_rep, $uiid_to_insert, $date_string, '$QQinteraction_originator', [ec_decode $interaction_type "other" "'$QQinteraction_type_other'" "'$QQinteraction_type'"])
    "
}

# IV. Issue (unless we already have an issue):
#   1. Have to insert into ec_customer_service_issues:
#     A. issue_id (passed along or generated)
#     B. user_identification_id (= uiid_to_insert determined in II)
#     C. order_id
#     D. open_date
#     E. close_date (=null if close_issue_p=f, =open_date if close_issue_p=t)
#     F. closed_by (=null if close_issue_p=f, =customer_service_rep if close_issue_p=t)
#   2. Have to insert into ec_cs_issue_type_map:
#     issue_id & issue_type for each issue_type in issue_type_list


if { $create_new_issue_p == "t" } {
    ns_db dml $db "insert into ec_customer_service_issues
    (issue_id, user_identification_id, order_id, open_date, close_date, closed_by)
    values
    ($issue_id, $uiid_to_insert, '$order_id', $date_string, [ec_decode $close_issue_p "t" $date_string "''"], [ec_decode $close_issue_p "t" $customer_service_rep "''"])
    "
    
    foreach issue_type $issue_type_list {
	ns_db dml $db "insert into ec_cs_issue_type_map
	(issue_id, issue_type)
	values
	($issue_id, '[DoubleApos $issue_type]')
	"
    }
}

# V. Action:
#  1. Have to insert into ec_customer_service_actions:
#     A. action_id
#     B. issue_id (passed along or generated)
#     C. interaction_id (generated in II)
#     D. action_details
#     E. follow_up_required
#  2. Have to insert into ec_cs_action_info_used_map:
#     action_id and info_used for each info_used in info_used_list   

ns_db dml $db "insert into ec_customer_service_actions
(action_id, issue_id, interaction_id, action_details, follow_up_required)
values
($action_id, $issue_id, $interaction_id, '$QQaction_details','$QQfollow_up_required')
"

foreach info_used $info_used_list {
    ns_db dml $db "insert into ec_cs_action_info_used_map
    (action_id, info_used)
    values
    ($action_id, '[DoubleApos $info_used]')
    "
}

ns_db dml $db "end transaction"


if { $submit == "Interaction Complete" } {
    if { ![info exists return_to_issue] } {
	ad_returnredirect interaction-add.tcl
    } else {
	ad_returnredirect "issue.tcl?issue_id=$return_to_issue"
    }
} else {
    # (in c_user_identification_id, "c" stands for "confirmed" meaning
    # that they've been through interaction-add-3.tcl and now they cannot change
    # the user_identification_id)
    ad_returnredirect "interaction-add-2.tcl?[export_url_vars interaction_id postal_code return_to_issue]&c_user_identification_id=$uiid_to_insert"
}
