# $Id: category-associate.tcl,v 3.0 2000/02/06 03:21:39 ron Exp $
set_the_usual_form_variables
# template_id

set db [ns_db gethandle]
set selection [ns_db 1row $db "select template_name, template from ec_templates where template_id=$template_id"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "Associate with a Category"]

<h2>Associate with a Category</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Templates"] [list "one.tcl?template_id=$template_id" "$template_name"] "Associate with a Category"]

<hr>
The point of doing this is just to make it a little faster when you are adding new products.
It is completely optional.

<p>

If you associate this template with a product category, then whenever you add a new product of that category,
the product will by default be set to display with this template, although you can always change it.  (However, if you 
add a new product and put it in more than one category, then this template might not end
up being the default for that product.)

<p>

This template may be associated with as many categories as you like.
"
# see if it's already associated with any categories

set n_categories_associated_with [database_to_tcl_string $db "select count(*) from ec_category_template_map where template_id=$template_id"]

if { $n_categories_associated_with > 0 } {
    set selection [ns_db select $db "select m.category_id, c.category_name
from ec_category_template_map m, ec_categories c
where m.category_id = c.category_id
and m.template_id = $template_id"]

    ns_write "Currently this template is associated with the category(ies):\n<ul>\n"

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	ns_write "<li>$category_name\n"
    }

    ns_write "</ul>\n"

} else {
    ns_write " This template has not yet been associated with any categories."
}

# see if there are any categories left to associate it with
set n_categories_left [database_to_tcl_string $db "select count(*)
from ec_categories
where category_id not in (select category_id from ec_category_template_map where template_id=$template_id)"]

if { $n_categories_left == 0 } {
    ns_write "All categories are associated with this template.  There are none left to add!"
} else {

    ns_write "<form method=post action=category-associate-2.tcl>
    [export_form_vars template_id]
    
    Category: 
    <select name=category_id>
    "
    
    set selection [ns_db select $db "select category_id, category_name
    from ec_categories
    where category_id not in (select category_id from ec_category_template_map where template_id=$template_id)"]
    
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	ns_write "<option value=\"$category_id\">$category_name\n"
    }
    
    ns_write "</select>
    <input type=submit value=\"Associate\">
    </form>
    "
}

ns_write "[ad_admin_footer]
"
