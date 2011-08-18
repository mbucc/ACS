# $Id: category-delete.tcl,v 3.0.4.1 2000/04/28 15:08:25 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# category

set db [ns_db gethandle]

# see if there are any calendar entries

set num_category_entries [database_to_tcl_string $db "select count(calendar_id) from calendar where category='$QQcategory'"]

if { $num_category_entries == 0 } {

    # no calendar entries, so just delete
    ad_returnredirect "category-delete-2.tcl?category=[ns_urlencode $category]"
    return
}

ReturnHeaders
ns_write "[ad_admin_header "Delete Category $category"]
<h2>Delete </h2>
category  <a href=\"category-one.tcl?category=[ns_urlencode $category]\">$category</a>
<hr>



There are entries in the database that currently are categories with the category $category. 
<p>
Would you like to:
<p>
<A href=\"category-delete-2.tcl?[export_url_vars category]\">Leave these items with category $category</a>

<p>
or change the category to one of the following:
<p>
<ul>
"
set counter 0
foreach category_new [database_to_tcl_list $db "select category as category_new from calendar_categories where category <> '$QQcategory' and enabled_p <> 'f'"] {

    incr counter
    ns_write "<li><a href=\"category-edit.tcl?[export_url_vars category_new category]\">$category_new</a>\n
"
}

if { $counter == 0 } {
    ns_write "no event categories are currently defined; this is an
error in system configuration and you should complain to 
[calendar_system_owner]"
}

ns_write "

</ul>

[ad_admin_footer]
"
 
