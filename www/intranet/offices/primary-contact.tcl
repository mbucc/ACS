# $Id: primary-contact.tcl,v 3.1.4.1 2000/03/17 08:23:02 mbryzek Exp $
# File: /www/intranet/offices/primary-contact.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Allows user to choose primary contact for office
# 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables
# group_id

# Avoid hardcoding the url stub
set target [ns_conn url]
regsub {primary-contact.tcl} $target {primary-contact-2.tcl} target

set db [ns_db gethandle]

set office_name [database_to_tcl_string $db \
	"select g.group_name
           from im_offices o, user_groups g
          where o.group_id = $group_id
            and o.group_id=g.group_id"]

ns_db releasehandle $db

set page_title "Select primary contact for $office_name"
set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Offices"] [list view.tcl?[export_url_vars group_id] "One office"] "Select contact"]

set page_body "

Locate your new primary contact by

<form method=get action=/user-search.tcl>
[export_form_vars group_id target limit_to_group_id]
<input type=hidden name=passthrough value=group_id>

<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>

<p>

<center>
<input type=submit value=Search>
</center>
</form>

"

ns_return 200 text/html [ad_partner_return_template]