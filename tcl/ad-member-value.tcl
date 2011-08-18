# $Id: ad-member-value.tcl,v 3.0 2000/02/06 03:12:31 ron Exp $
#
# /tcl/ad-member-value.tcl
#
# by philg@mit.edu in July 1998 
# modified November 7, 1999 to include interface
# to the ad-user-contributions-summary.tcl system

# anything having to do with billing members
# or tallying up their charges (pseudo or otherwise)


util_report_library_entry

proc_doc mv_parameter {name {default ""}} "The correct way to get a parameter for the member value module.  We want to make sure that we are abstracting away whether this is stored in the database or in the /parameters/ad.ini file." {
    set server_name [ns_info server]
    append config_path "ns/server/" $server_name "/acs/member-value"
    set config_value [ns_config $config_path $name]
    if ![empty_string_p $config_value] {
	return $config_value
    } else {
	return $default
    }
}

proc_doc mv_create_user_charge {user_id admin_id charge_type charge_key amount {charge_comment ""}} "Build a user charge data structure (actually just a list)" {
    return [list $user_id $admin_id $charge_type $charge_key $amount $charge_comment]
}

proc_doc mv_user_charge_replace_comment {user_charge new_comment} "Takes a user charge data structure (actually just a list) and replaces the comment field (at the end); useful when there is a separate field for an admin to type an arbitrary comment." {
    set user_id [lindex $user_charge 0]
    set admin_id [lindex $user_charge 1]
    set charge_type [lindex $user_charge 2]
    set charge_key [lindex $user_charge 3]
    set amount [lindex $user_charge 4]
    return [list $user_id $admin_id $charge_type $charge_key $amount $new_comment]
}

# the argument is 
# [list user_id admin_id charge_type charge_key amount charge_comment]
# note that it doesn't contain the entry_date, which we'll 
# add implicitly

proc_doc mv_charge_user {db spec_list {notify_subject ""} {notify_body ""}} "Takes a spec in the form of \[list user_id admin_id charge_type charge_key amount charge_comment\] and adds a row to the users_charges table" {
    # we double the apostrophes right here to avoid any trouble with SQL
    set QQspec_list [DoubleApos $spec_list]
    set user_id [lindex $QQspec_list 0]
    set admin_id [lindex $QQspec_list 1]
    set charge_type [lindex $QQspec_list 2]
    set charge_key [lindex $QQspec_list 3]
    set amount [lindex $QQspec_list 4]
    set unquoted_charge_comment [lindex $spec_list 5]
    ns_db dml $db "insert into users_charges 
(user_id, admin_id, charge_type, charge_key, amount, charge_comment, entry_date)
values
($user_id, $admin_id, '$charge_type', '$charge_key', $amount, [ns_dbquotevalue $unquoted_charge_comment text], sysdate)"
    if ![empty_string_p $notify_subject] {
	# we're going to email this user and tell him that we charged him
	# but we don't want an error in notification to cause this to fail
	catch { mv_notify_user_of_new_charge $db $spec_list $notify_subject $notify_body }
    }
}

proc_doc mv_notify_user_of_new_charge {db spec_list notify_subject notify_body} "Helper proc for mv_charge_user; actually sends email." {
    set user_id [lindex $spec_list 0]
    set admin_id [lindex $spec_list 1]
    set charge_type [lindex $spec_list 2]
    set charge_key [lindex $spec_list 3]
    set amount [lindex $spec_list 4]
    set charge_comment [lindex $spec_list 5]
    set user_email [database_to_tcl_string_or_null $db "select email from users_alertable where user_id = $user_id"]
    set admin_email [database_to_tcl_string_or_null $db "select email from users where user_id = $admin_id"]
    if { ![empty_string_p $user_email] && ![empty_string_p $admin_id] } {
	set full_body "You've been assessed a charge by the [ad_system_name] community."
	if [ad_parameter UseRealMoneyP "member-value"] {
	    append full_body "\n\nThis charge will be included in your next bill."
	} else {
	    append full_body "\n\nWe don't use real money here but the charges are 
designed to reflect the reality of the costs of your actions.
It is only possible to operate community Web services if 
members conform to certain norms."
	}
	append full_body "\n\nHere's a summary of the charge:
[mv_describe_user_charge $spec_list]\n\n"
        append full_body "More explanation:\n\n$notify_body"
        ns_log Notice "mv_notify_user_of_new_charge sending email from $admin_email to $user_email"
        ns_sendmail $user_email $admin_email $notify_subject $notify_body
    }
}

proc_doc mv_describe_user_charge {spec_list} "Takes a spec in the form of \[list user_id admin_id charge_type charge_key amount charge_comment\] and prints a readable description." {
    set user_id [lindex $spec_list 0]
    set admin_id [lindex $spec_list 1]
    set charge_type [lindex $spec_list 2]
    set charge_key [lindex $spec_list 3]
    set amount [lindex $spec_list 4]
    set charge_comment [lindex $spec_list 5]
    set description  "$charge_type:  $amount; user ID $user_id (by administrator $admin_id)"
    if ![empty_string_p $charge_comment] {
	append description "; $charge_comment"
    }
    return $description
}

# stuff for reporting

proc mv_pretty_currency {currency} {
    if { $currency == "USD" } {
	return "&#36;"
    } elseif { $currency == "GBP" } {
	return "&pound;"
    } else {
	return $currency
    }
}

proc mv_pretty_amount {currency amount} {
    if { $currency == "USD" } {
	return "&#36;[format "%0.2f" $amount]"
    } elseif { $currency == "GBP" } {
	return "&pound;$amount"
    } else {
	return "$currency$amount"
    }
}

proc mv_pretty_user_charge {charge_type charge_key charge_comment} {
    # pretty (and maybe hyperlinked) descriptions of a charge
    switch $charge_type {
	miscellaneous { set result "$charge_type: $charge_comment" }
	default { set result "$charge_type: $charge_comment" }
    }
    return $result 
}

proc_doc mv_enabled_p {} "Just a shortcut for seeing if the member value module is enabled." {
    return [ad_parameter EnabledP "member-value" 0]
}

proc_doc mv_rate {which_rate} "A shortcut for getting a rate from the member-value section of the parameters file" {
    return [ad_parameter $which_rate "member-value"]
}


##################################################################
#
# interface to the ad-user-contributions-summary.tcl system

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Member Value" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Member Value" mv_user_contributions 0]
}

proc_doc mv_user_contributions {db user_id purpose} {Returns empty list unless it is the site admin asking.  Returns list items, one for each user charge} {
    if { $purpose != "site_admin" } {
	return [list]
    } 
    set items ""
    set selection [ns_db select $db "select 
  uc.entry_date, 
  uc.charge_type, 
  uc.currency, 
  uc.amount,
  uc.charge_comment,
  uc.admin_id,
  u.first_names || ' ' || u.last_name as admin_name
from users_charges uc, users u
where uc.user_id = $user_id
and uc.admin_id = u.user_id
order by uc.entry_date desc"]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append items "<li>$entry_date: $charge_type $currency $amount, 
by <a href=\"/admin/member-value/charges-by-one-admin.tcl?admin_id=$admin_id\">$admin_name</a>"
        if ![empty_string_p $charge_comment] {
	    append items " ($charge_comment)"
	}
	append items "\n"
    }
    if [empty_string_p $items] {
	return [list]
    } else {
	return [list 0 "Member Value" "<ul>\n\n$items\n\n</ul>"]
    }
}



util_report_successful_library_load
