# $Id: send.tcl,v 1.1.2.2 2000/03/17 08:56:40 mbryzek Exp $

# File: /www/intranet/spam/send.tcl
# Author: mbryzek@arsdigita.com, Mar 2000
# Sends email to users specified

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

set email_list [database_to_tcl_list $db \
	"select distinct u.email
           from users_active u, user_group_map ugm
          where u.user_id=ugm.user_id [im_spam_multi_group_exists_clause $group_id_list]"]

ns_db releasehandle $db

if { [exists_and_not_null description] } {
    set description_html "<br><b>Description:</b> $description\n"
} else {
    set description_html ""
}

set page_title "Sending email"
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] [list index.tcl?[export_ns_set_vars url] "Spam users"] "Sending email"]


set page_body "
$description_html

<p>Sending email
<ol>
"

foreach email $email_list {
    append page_body "  <li> $email"
    if { [catch {ns_sendmail $email $from_address $subject $message} err_msg] } {
	append page_body " Error: $err_msg"
    }
    append page_body "\n"
}

append page_body "</ol>\n"

if { [exists_and_not_null return_url] } {
    append page_body "<a href=\"$return_url\">Go back to where you were</a>\n"
}


ns_return 200 text/html [ad_partner_return_template]