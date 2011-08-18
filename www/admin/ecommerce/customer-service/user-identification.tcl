# $Id: user-identification.tcl,v 3.0.4.1 2000/04/28 15:08:41 carsten Exp $
set_the_usual_form_variables
# user_identification_id

set db [ns_db gethandle]
set selection [ns_db 1row $db "select * from ec_user_identification where user_identification_id=$user_identification_id"]
set_variables_after_query

if { ![empty_string_p $user_id] } {
    ad_returnredirect "/admin/users/one.tcl?user_id=$user_id"
    return
}

ReturnHeaders

set page_title "Unregistered User"
ns_write "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>

<h3>What we know about this user</h3>

<table>
<tr>
<td align=right><b>First Name</td>
<td>$first_names</td>
</tr>
<tr>
<td align=right><b>Last Name</td>
<td>$last_name</td>
</tr>
<tr>
<td align=right><b>Email</td>
<td>$email</td>
</tr>
<tr>
<td align=right><b>Zip Code</td>
<td>$postal_code
"

set location [ec_location_based_on_zip_code $db $postal_code]
if { ![empty_string_p $location] } {
    ns_write " ($location)"
}

ns_write "</td>
</tr>
<tr>
<td align=right><b>Other Identifying Info</td>
<td>$other_id_info</td>
</tr>
<tr>
<td align=right><b>Record Created</b></td>
<td>[util_AnsiDatetoPrettyDate $date_added]</td>
</tr>
</table>

<h3>Customer Service Issues</h3>

[ec_all_cs_issues_by_one_user $db "" $user_identification_id]

<h3>Edit User Info</h3>

<form method=post action=user-identification-edit.tcl>
[export_form_vars user_identification_id]
<table>
<tr>
<td>First Name:</td>
<td><input type=text name=first_names size=15 value=\"[philg_quote_double_quotes $first_names]\"> Last Name: <input type=text name=last_name size=20 value=\"[philg_quote_double_quotes $last_name]\"></td>
</tr>
<tr>
<td>Email Address:</td>
<td><input type=text name=email size=30 value=\"[philg_quote_double_quotes $email]\"></td>
</tr>
<tr>
<td>Zip Code:</td>
<td><input type=text name=postal_code size=5 maxlength=5 value=\"[philg_quote_double_quotes $postal_code]\"></td>
</tr>
<tr>
<td>Other Identifying Info:</td>
<td><input type=text name=other_id_info size=30 value=\"[philg_quote_double_quotes $other_id_info]\"></td>
</tr>
</table>

<center>
<input type=submit value=\"Update\">
</center>
</form>

<h3>Try to match this user up with a registered user</h3>
<ul>
<form method=post action=user-identification-match.tcl>
[export_form_vars user_identification_id]
"

set positively_identified_p 0


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
    # see if they have a gift certificate that a registered user has claimed.
    # email_template_id 5 is the automatic email sent to gift certificate recipients.
    # it's kind of convoluted, but so is this whole user_identification thing
    set selection [ns_db select $db "select g.user_id as d_user_id, u.first_names as d_first_names, u.last_name as d_last_name
    from ec_automatic_email_log l, ec_gift_certificates g, users u
    where g.user_id=u.user_id
    and l.gift_certificate_id=g.gift_certificate_id
    and l.user_identification_id=$user_identification_id
    and l.email_template_id=5
    group by g.user_id, u.first_names, u.last_name"]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	ns_write "<li>This may be the registered user <a target=user_window href=\"/admin/users/one.tcl?user_id=$d_user_id\">$d_first_names $d_last_name</a> who claimed a gift certificate sent to $email (check here <input type=checkbox name=d_user_id value=$d_user_id> if this is correct).\n"
    }
}

if { [info exists d_user_id] } {
    ns_write "<p>
    <center>
    <input type=submit value=\"Confirm they are the same person\">
    </center>"
} else {
    ns_write "No matches found."
}

ns_write "</form>
</ul>
[ad_admin_footer]
"