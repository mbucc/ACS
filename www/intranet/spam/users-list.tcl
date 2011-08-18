# $Id: users-list.tcl,v 1.1.2.2 2000/03/17 08:56:41 mbryzek Exp $

# File: /www/intranet/spam/users-list.tcl
# Author: mbryzek@arsdigita.com, Mar 2000
# Lists all users who are about to be spammed

set_form_variables 0
# group_id_list (comma separated list of group_id that users must be in)
# description (optional - replaces page_title if it's specified)

if { ![exists_and_not_null group_id_list] } {
    ad_return_complaint 1 "Missing group id(s)"
    return
}

set db [ns_db gethandle]

set selection [ns_db select $db \
	"select distinct u.user_id, u.first_names || ' ' || u.last_name as user_name, u.email
           from users_active u, user_group_map ugm
          where u.user_id=ugm.user_id [im_spam_multi_group_exists_clause $group_id_list]"]

set page_title "Users who are about to receive your spam"
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] [list index.tcl?[export_ns_set_vars url] "Spam users"] "View users"]

set page_body "<ol>\n"
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append page_body "  <li> <a href=../users/view.tcl?[export_url_vars user_id]>$user_name</a> - <a href=mailto:$email>$email</a>\n"
}

append page_body "</ol>\n"

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]