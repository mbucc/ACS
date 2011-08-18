# $Id: category-administrator-update.tcl,v 3.0 2000/02/06 03:25:53 ron Exp $
set_form_variables 0

# category_id 

set db [ns_db gethandle]


set selection [ns_db 1row $db "select n_to_n_primary_categories.*,
users.email from n_to_n_primary_categories, users
where category_id = $category_id
and users.user_id(+) = n_to_n_primary_categories.primary_maintainer_id"] 
set_variables_after_query
set action "Edit  $primary_category administrator"


ReturnHeaders

ns_write "[neighbor_header "$action"]

<h2>$action</h2>

[ad_admin_context_bar [list "index.tcl" "Neighbor to Neighbor"] [list "category.tcl?[export_url_vars category_id]" "One Category"] "Update Administrator"]

<hr>

<form action=\"/user-search.tcl\" method=post>
<input type=hidden name=target value=\"/admin/neighbor/category-administrator-update-2.tcl\">
<input type=hidden name=passthrough value=\"category_id\">
<input type=hidden name=custom_title value=\"Choose a Member to select as an Administrator\">

<h3></h3>
<p>
Search for a user to be primary administrator of this domain by<br>
<table border=0>
<tr><td>Email address:<td><input type=text name=email  size=40 [export_form_value email]></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>

<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars category_id]
</form>
[neighbor_footer]
"
