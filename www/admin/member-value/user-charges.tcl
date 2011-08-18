# $Id: user-charges.tcl,v 3.0 2000/02/06 03:25:07 ron Exp $
# 
# /admin/member-value/user-charges.tcl
#
# by philg@mit.edu in July 1998
# 
# shows all the charges for one user
#

set_the_usual_form_variables

# note: nobody gets to this page who isn't a site administrator (ensured
# by a filter in ad-security.tcl)

# user_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select first_names, last_name from users where user_id = $user_id"]
set_variables_after_query

ReturnHeaders 
ns_write "[ad_admin_header "Charges for $first_names $last_name"]

<h2>Charge history</h2>

[ad_admin_context_bar [list "index.tcl" "Member Value"] "Charges for one user"]

<hr>

User: <a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a>

<p>



Add a miscellaneous charge:

<form method=POST action=\"add-charge.tcl\">
<input type=hidden name=user_id value=\"$user_id\">
<input type=hidden name=charge_type value=\"miscellaneous\">
<table>
<tr>
<th>Amount:
<td><input type=text size=7 name=amount>
</tr>
<tr>
<th>Comment
<th><input type=text name=charge_comment size=50>
</tr>
</table>
<center>
<input type=submit value=\"Add\">
</center>
</form>

<h3>Older Charges</h3>

<ul>

"


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

set items ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append items "<li>$entry_date: $charge_type $currency $amount, 
by <a href=\"/admin/member-value/charges-by-one-admin.tcl?admin_id=$admin_id\">$admin_name</a>"
    if ![empty_string_p $charge_comment] {
	append items " ($charge_comment)"
    } 
    append items "\n"
}

if { [empty_string_p $items] } {
    ns_write "no charges found"
} else {
    ns_write $items
}

ns_write "
</ul>
[ad_admin_footer]
"
