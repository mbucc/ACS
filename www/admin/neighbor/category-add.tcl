# $Id: category-add.tcl,v 3.0 2000/02/06 03:25:49 ron Exp $
set_form_variables 0

# either category_id or subcategory_id

set db [ns_db gethandle]

if { [info exists category_id] } {
    # get the previous data
    set selection [ns_db 1row $db "select n_to_n_primary_categories.*,
users.email from n_to_n_primary_categories, users
where category_id = $category_id
and users.user_id(+) = n_to_n_primary_categories.primary_maintainer_id"] 
    set_variables_after_query
    set action "Edit category $primary_category"
} else {
    set action "Add a new category"
    # generate a new category_id to use
    set category_id [database_to_tcl_string $db "select
n_to_n_primary_category_id_seq.nextval from dual"]
} 

ReturnHeaders

ns_write "[ad_admin_header "$action"]

<h2>$action</h2>

[ad_admin_context_bar [list "index.tcl" "Neighbor to Neighbor"] $action]

<hr>

<form action=\"/user-search.tcl\" method=post>
<input type=hidden name=target value=\"/admin/neighbor/category-add-2.tcl\">
<input type=hidden name=passthrough value=\"category_id primary_category approval_policy\">
<input type=hidden name=custom_title value=\"Choose a Member to Add as an Administrator\">

<h3></h3>

What would you like to call this category?  <input type=text maxlength=100 name=primary_category [export_form_value primary_category]>
<p>
Search for a user to be primary administrator of this domain by<br>
<table border=0>
<tr><td>Email address:<td><input type=text name=email  size=40 [export_form_value email]></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>
<p>
What type of approval system would you like for new postings?<br>
<select name=approval_policy>
[ad_generic_optionlist { "Open posting" "Admin approves postings" "Closed - Admin only" } { open wait closed } [export_var approval_policy]] 
</select>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars category_id]
</form>
[ad_admin_footer]
"
