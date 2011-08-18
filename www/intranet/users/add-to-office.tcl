# $Id: add-to-office.tcl,v 3.2.2.1 2000/03/17 08:23:20 mbryzek Exp $
# File: /www/intranet/users/add-to-office.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Shows a list of offices to which to add a specified user
#

ad_maybe_redirect_for_registration

set_form_variables
# user_id
# return_url (optional)

set db [ns_db gethandle]

set user_name [database_to_tcl_string_or_null $db \
	"select first_names || ' ' || last_name from users_active where user_id=$user_id"]

if { [empty_string_p $user_name] } {
    ad_return_error "User doesn't exists!" "This user does not exist or is inactive"
    return
}

set selection [ns_db select $db \
	"select g.group_id, g.group_name
           from user_groups g, im_offices o
          where o.group_id=g.group_id
       order by lower(g.group_name)"]

set results ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append results "  <li> <a href=/groups/member-add-3.tcl?user_id_from_search=$user_id&role=member&[export_url_vars group_id return_url]>$group_name</a>\n"
}

if { [empty_string_p $results] } {
    set page_body "<ul>  <li><b> There are no offices </b></ul>\n" 
} else {
    set page_body "
<b>Choose office for this user:</b>
<ul>$results</ul>
"
}

ns_db releasehandle $db

set page_title "Add user to office"
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" "Intranet"] [list "./" "Users"] [list view.tcl?[export_url_vars user_id] "One user"] $page_title]

ns_return 200 text/html [ad_partner_return_template]
