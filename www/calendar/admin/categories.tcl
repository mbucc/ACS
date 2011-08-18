# $Id: categories.tcl,v 3.0 2000/02/06 03:36:01 ron Exp $
# File:     /calendar/admin/categories.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  lists all categories
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe contact_info_only, maybe order_by

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

ReturnHeaders

ns_write "
[ad_scope_admin_header "Calendar categories" $db]
[ad_scope_admin_page_title "Categories" $db ]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Calendar"] "Categories"]

<hr>

<ul>

"

set selection [ns_db select $db "
select category_id, category, enabled_p 
from calendar_categories
where [ad_scope_sql]
order by enabled_p desc"]

set counter 0
set enabled_headline_shown_p 0
set disabled_headline_shown_p 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    if { $enabled_headline_shown_p == 0 && $enabled_p == "t" } {
	ns_write "<h4>Categories in which users can post</h4>
<ul>"
	set enabled_headline_shown_p 1
    } 

    if { $disabled_headline_shown_p == 0 && $enabled_p == "f" } {
	ns_write "</ul>
<h4>Disabled Categories</h4>
<ul>"
	set disabled_headline_shown_p 1
    } 

    ns_write "<li><a href=\"category-one.tcl?[export_url_scope_vars]&category_id=[ns_urlencode $category_id]\">$category</a>\n"
}

if { $counter == 0 } {
    ns_write "no event categories are currently defined"
}


set category_id [database_to_tcl_string $db "select calendar_category_id_sequence.nextval from dual" ]

ns_write "
<P>
<li><form method=post action=category-new.tcl>
[export_form_scope_vars category_id]
Add a category:
<input type=text name=category_new>
<input type=submit name=submit value=\"Add\">
</form>
</ul>

<p>

<i>Typical categories for a site like photo.net 
might include \"Workshops\", \"Museum Exhibitions\", \"Lectures\".  
Any kind of thing that you might want to know about long in advance.
</i>
</ul>
[ad_scope_admin_footer]
"
 




