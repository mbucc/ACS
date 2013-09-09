# spam.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id spam.tcl,v 3.2.6.5 2000/09/22 01:34:54 kevin Exp
} {
}


set return_url "[ad_conn url]"

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}



append doc_body "[ad_admin_header "Spam Users"]
<h2>Spam Users</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "Spam Users"]

<hr>
<p align=right>
<a href=\"spam-log\">View spam log</a>
</p>
"



append doc_body "<ol>

<b><li>Spam all users in a mailing list:</b>

<form method=post action=spam-2>
Mailing lists: [ec_mailing_list_widget]<br>
<input type=checkbox name=show_users_p value=\"t\" checked>Show me the users who will be spammed.<br>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

<p>

<b><li>Spam all members of a user class:</b>

<form method=post action=spam-2>
User classes: [ec_user_class_widget]<br>
<input type=checkbox name=show_users_p value=\"t\" checked>Show me the users who will be spammed.<br>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

<p>

<b><li>Spam all users who bought this product:</b>

<form method=post action=spam-2>
Product ID: <input type=text name=product_id size=5><br>
<input type=checkbox name=show_users_p value=\"t\" checked>Show me the users who will be spammed.<br>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

<p>

<b><li>Spam all users who viewed this product:</b>

<form method=post action=spam-2>
Product ID: <input type=text name=viewed_product_id size=5><br>
<input type=checkbox name=show_users_p value=\"t\" checked>Show me the users who will be spammed.<br>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

<p>

<b><li>Spam all users who viewed this category:</b>

<form method=post action=spam-2>
Category: [ec_only_category_widget]<br>
<input type=checkbox name=show_users_p value=\"t\" checked>Show me the users who will be spammed.<br>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

<p>

<b><li>Spam all users whose last visit was:</b>

<form method=post action=spam-2>
"

# this proc uses uplevel and assumes the existence of
# it sets the variables start_date and end_date
ec_report_get_start_date_and_end_date

append doc_body "
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


doc_return  200 text/html $doc_body

