# File:  events/admin/order-history.tcl
# Owner: bryanche@arsdigita.com
# Purpose: Present a selection of views for order history.
#####

ad_page_contract {
    Present a selection of views for order history.

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id order-history.tcl,v 3.4.6.3 2000/09/22 01:37:38 kevin Exp
} {
}

doc_return  200 text/html "[ad_header "[ad_system_name] Events Administration: Events Order History"]

<h2>Order History</h2>
[ad_context_bar_ws [list "index.tcl" "Events Administration"] "Order History"]
<hr>

<h3>View Orders/Statistics by:</h3>
<ul>
 <li><a href=\"order-history-activity\">Activity</a>
 <li><a href=\"order-history-month\">Month</a> | <a href=\"order-history-date\">Day</a>
 <li><a href=\"order-history-ug\">User Group</a>
 <li><a href=\"order-history-one\">Registration Number</a>
 <li><a href=\"order-history-state\">Registration State</a>
</ul>

<br>
<h3>Search For an Individual Registration:</h3>

<form method=post action=order-search>
Enter either the registration number <b>or</b> the customer's last name for the order you wish to view:<br>
<ul><table>
<tr><td><input type=text size=5 name=id_query></td><td><input type=text size=15 name=name_query></td><td rowspan=2 valign=middle> &nbsp;&nbsp;&nbsp;&nbsp;<input type=submit value=\"Search For Registration\"></td></tr>
<tr><td align=center>Registration #</td><td align=center>Last Name</td></tr>
</table></ul>
</form>

[ad_footer]
"
##### EOF
