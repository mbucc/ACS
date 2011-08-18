# $Id: category-one.tcl,v 3.0 2000/02/06 03:36:08 ron Exp $
# File:     /calendar/admin/category-one.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  shows one category
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# category_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

set category [database_to_tcl_string $db "
select category
from calendar_categories 
where category_id=$category_id "]
 

ReturnHeaders

ns_write "
[ad_scope_admin_header "Category $category" $db]
[ad_scope_admin_page_title "Category $category" $db]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Calendar"] [list "categories.tcl?[export_url_scope_vars]" "Categories"] "One Category"]  

<hr>

<ul>
"

set selection [ns_db select $db "
select calendar.*, expired_p(expiration_date) as expired_p
from calendar
where  category_id = $category_id
order by expired_p, creation_date desc"]

set counter 0 
set expired_p_headline_written_p 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter 
    if { $expired_p == "t" && !$expired_p_headline_written_p } {
	ns_write "<h4>Expired Calendar Items</h4>\n"
	set expired_p_headline_written_p 1
    }
    ns_write "<li>[util_AnsiDatetoPrettyDate $start_date] - [util_AnsiDatetoPrettyDate $end_date]: <a href=\"item.tcl?[export_url_scope_vars calendar_id]\">$title</a>"
    if { $approved_p == "f" } {
	ns_write "&nbsp; <font color=red>not approved</font>"
    }
    ns_write "\n"
}

ns_write "

<P>

<li><a href=\"post-new-2.tcl?[export_url_scope_vars]&category=[ns_urlencode $category]\">Add an item</a>

<p>

<li>

<form method=post action=category-edit.tcl>
Change this category name:
[export_form_scope_vars category_id]
<input type=text name=category_new value=\"[philg_quote_double_quotes $category]\">
<input type=submit name=submit value=\"Change\">
</form>"

set category_enabled_p [database_to_tcl_string $db "
select enabled_p from calendar_categories where category_id=$category_id"]

if {$category_enabled_p == "t"} {
    ns_write "<li> <A href=\"category-delete.tcl?[export_url_scope_vars]&category_id=[ns_urlencode $category_id]\">Delete this category</a>"
} else {
    ns_write "<li> <A href=\"category-enable-toggle.tcl?[export_url_scope_vars]&category_id=[ns_urlencode $category_id]\">Allow users to post to this category</a>"
}
ns_write "</ul>
[ad_scope_admin_footer]
"






