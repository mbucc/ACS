# $Id: confirm.tcl,v 1.1.2.2 2000/03/17 08:56:39 mbryzek Exp $

# File: /www/intranet/spam/confirm.tcl
# Author: mbryzek@arsdigita.com, Mar 2000
# Confirmation screen before email is sent.

set_form_variables 0
# group_id_list (comma separated list of group_id that users must be in)
# description (optional - replaces page_title if it's specified)

set required_vars [list \
	[list group_id_list "Missing group id(s)"] \
	[list from_address "Missing from address"] \
	[list subject "Missing subject"] \
	[list message "Missing message"]]

set errors [im_verify_form_variables $required_vars]

if { ![empty_string_p $errors] } {
    ad_return_complaint 2 $errors
    return
}

set db [ns_db gethandle]

set exists_p [database_to_tcl_string_or_null $db \
	"select count(1) from user_groups where group_id in ($group_id_list)"]

if { $exists_p == 0 } {
    ad_return_complaint 1 "The specified group(s) (#$group_id_list) could not be found"
    return
}

set number_users_to_spam [im_spam_number_users $db $group_id_list]

if { $number_users_to_spam == 0 } {
    ad_return_complaint 1 "There are no active users to spam!"
    return
}

ns_db releasehandle $db

if { [exists_and_not_null description] } {
    set description_html "<br><b>Description:</b> $description\n"
} else {
    set description_html ""
}

set page_title "Confirm email"
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] [list index.tcl?[export_ns_set_vars url] "Spam users"] "Confirm email"]

set page_body "
<b>This email will go to $number_users_to_spam [util_decode $number_users_to_spam 1 "user" "users"]
(<a href=users-list.tcl?[export_url_vars group_id_list description return_url]>view</a>).</b>
$description_html
<p> 

<pre>
From: $from_address
Subject: $subject
------------------
[wrap_string $message]
</pre>

[im_yes_no_table send.tcl cancel.tcl [list group_id_list description return_url from_address subject message]]
"
 
ns_return 200 text/html [ad_partner_return_template]