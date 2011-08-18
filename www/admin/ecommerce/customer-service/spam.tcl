# $Id: spam.tcl,v 3.0.4.1 2000/04/28 15:08:41 carsten Exp $
set return_url "[ns_conn url]"

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

ReturnHeaders

ns_write "[ad_admin_header "Spam Users"]
<h2>Spam Users</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "Spam Users"]

<hr>
<p align=right>
<a href=\"spam-log.tcl\">View spam log</a>
</p>
"

set db [ns_db gethandle]

ns_write "<ol>

<b><li>Spam all users in a mailing list:</b>

<form method=post action=spam-2.tcl>
Mailing lists: [ec_mailing_list_widget $db]<br>
<input type=checkbox name=show_users_p value=\"t\" checked>Show me the users who will be spammed.<br>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

<p>

<b><li>Spam all members of a user class:</b>

<form method=post action=spam-2.tcl>
User classes: [ec_user_class_widget $db]<br>
<input type=checkbox name=show_users_p value=\"t\" checked>Show me the users who will be spammed.<br>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

<p>

<b><li>Spam all users who bought this product:</b>

<form method=post action=spam-2.tcl>
Product ID: <input type=text name=product_id size=5><br>
<input type=checkbox name=show_users_p value=\"t\" checked>Show me the users who will be spammed.<br>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

<p>

<b><li>Spam all users who viewed this product:</b>

<form method=post action=spam-2.tcl>
Product ID: <input type=text name=viewed_product_id size=5><br>
<input type=checkbox name=show_users_p value=\"t\" checked>Show me the users who will be spammed.<br>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

<p>

<b><li>Spam all users who viewed this category:</b>

<form method=post action=spam-2.tcl>
Category: [ec_only_category_widget $db]<br>
<input type=checkbox name=show_users_p value=\"t\" checked>Show me the users who will be spammed.<br>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

<p>

<b><li>Spam all users whose last visit was:</b>

<form method=post action=spam-2.tcl>
"

# this proc uses uplevel and assumes the existence of $db
# it sets the variables start_date and end_date
ec_report_get_start_date_and_end_date

ns_write "
[ec_report_date_range_widget $start_date $end_date]<br>
<input type=checkbox name=show_users_p value=\"t\" checked>Show me the users who will be spammed.<br>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

</ol>

[ad_admin_footer]
"