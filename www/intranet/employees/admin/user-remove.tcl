# $Id: user-remove.tcl,v 1.1.2.3 2000/03/17 07:26:13 mbryzek Exp $
#
# File: /www/intranet/employess/admin/user-remove.tcl
# Author: mbryzek@arsdigita.com, 3/15/2000
# Confirmation to remove specified user from all intranet groups

set_form_variables 0
# user_id
# return_url (optional)

if { ![exists_and_not_null user_id] } {
    ad_return_error "Missing user id!" "We are missing the user_id of the person you want to remove. Please back up, hit reload, and try again."
    return
}

set db [ns_db gethandle]

set user_name [database_to_tcl_string_or_null $db \
	"select first_names || ' ' || last_name from users where user_id='$user_id'"]

if { [empty_string_p $user_name] } {
    ad_return_error "User #$user_id Not Found" "We can't find a user with an id of $user_id. This user has probably been removed from the system"
    return
}

ns_db releasehandle $db

set page_title "Confirm removal"
set context_bar [ad_context_bar [list "/" Home] [list ../../index.tcl "Intranet"] [list index.tcl "Employees"] [list view.tcl?[export_url_vars user_id] "One employee"] $page_title]

set page_body "
Do you really want to remove $user_name from all intranet groups?

[im_yes_no_table user-remove-2.tcl user-remove-cancel.tcl [list user_id return_url]]
"

ns_return 200 text/html [ad_partner_return_template]
