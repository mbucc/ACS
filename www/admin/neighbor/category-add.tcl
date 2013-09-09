# /www/admin/neighbor/category-add.tcl
ad_page_contract {
    Adds or edits a category.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id category-add.tcl,v 3.2.2.5 2001/01/11 19:19:10 khy Exp
    @param category_id the ID of a category to edit.  if null, a new category is added
} {
    {category_id:integer,optional}
}

if { [info exists category_id] } {
    # get the previous data
    db_1row select_category "
      select n_to_n_primary_categories.*,
             users.email 
        from n_to_n_primary_categories, users
       where category_id = :category_id
         and users.user_id(+) = n_to_n_primary_categories.primary_maintainer_id"
    set action "Edit category $primary_category"
} else {
    set action "Add a new category"
    # generate a new category_id to use
    set category_id [db_string select_category_id "
      select n_to_n_primary_category_id_seq.nextval
        from dual"]
} 

set page_content "[ad_admin_header "$action"]

<h2>$action</h2>

[ad_admin_context_bar [list "" "Neighbor to Neighbor"] $action]

<hr>

<form action=\"/user-search\" method=post>
<input type=hidden name=target value=\"/admin/neighbor/category-add-2\">
<input type=hidden name=passthrough value=\"category_id primary_category approval_policy category_id:sig\">
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
[export_form_vars -sign category_id]
</form>
[ad_admin_footer]
"


doc_return  200 text/html $page_content