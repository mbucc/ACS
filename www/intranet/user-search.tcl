# $Id: user-search.tcl,v 3.1.2.1 2000/03/17 08:22:41 mbryzek Exp $
# 
# File: /www/intranet/user-search.tcl
#
# Author: mbryzek@arsdigita.com, Mar 2000
#
# Purpose: Standard form to search for a user (through /user-search.tcl)
#


set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables
# target
# passthrough



set page_title "Search for a user"
set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Offices"] [list view.tcl?[export_url_vars group_id] "One office"] "Select contact"]

set page_body "

Locate user by:

<form method=get action=/user-search.tcl>
[export_ns_set_vars form]

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