# $Id: user-subscription.tcl,v 3.0 2000/02/06 03:25:10 ron Exp $
set_the_usual_form_variables

# note: nobody gets to this page who isn't a site administrator (ensured
# by a filter in ad-security.tcl)

# user_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select unique * from users where user_id = $user_id"]
set_variables_after_query

ReturnHeaders 
ns_write "[ad_no_menu_header "Subscription for $first_names $last_name"]

<h2>Subscription Info</h2>

for <a href=\"../user-home.tcl?user_id=$user_id\">$first_names $last_name</a>
in <a href=\"../index.tcl\">[ad_system_name]</a>
<hr>

"

set selection [ns_db 0or1row $db "select * from users_payment where user_id = $user_id"]

if { $selection == "" } {
    ns_write "

<form method=POST action=\"user-subscription-classify.tcl\">
<input type=hidden name=user_id value=\"$user_id\">
Place user in a subscription class:
<select name=subscriber_class>
[db_html_select_options $db "select subscriber_class from mv_monthly_rates order by rate"]
</select>
<input type=submit value=\"Choose\">
</form>
"
} else {
    set_variables_after_query
    ns_write "Current subscription class:  <b>$subscriber_class</b>

<p>

<form method=POST action=\"user-subscription-classify.tcl\">
<input type=hidden name=user_id value=\"$user_id\">
Place user in a new subscription class:
<select name=subscriber_class>
[db_html_select_options $db "select subscriber_class from mv_monthly_rates order by rate" $subscriber_class]
</select>
<input type=submit value=\"Choose\">
</form>
"
}


ns_write "
</ul>
[ad_no_menu_footer]
"
