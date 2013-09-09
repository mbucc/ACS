# /www/admin/neighbor/category-administrator-update.tcl
ad_page_contract {
    Edits the administrator of a given category.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1996
    @cvs-id category-administrator-update.tcl,v 3.3.2.3 2000/09/22 01:35:41 kevin Exp
    @param category_id the ID of the category whose administrator should be changed
} {
    category_id:notnull,integer
}

db_1row select_category "
  select n_to_n_primary_categories.*,
         users.email 
    from n_to_n_primary_categories, users
   where category_id = :category_id
     and users.user_id(+) = n_to_n_primary_categories.primary_maintainer_id"
set action "Edit  $primary_category administrator"

set page_content "[neighbor_header "$action"]

<h2>$action</h2>

[ad_admin_context_bar [list "" "Neighbor to Neighbor"] [list "category?[export_url_vars category_id]" "One Category"] "Update Administrator"]

<hr>

<form action=\"/user-search\" method=post>
<input type=hidden name=target value=\"/admin/neighbor/category-administrator-update-2\">
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

db_release_unused_handles
doc_return 200 text/html $page_content