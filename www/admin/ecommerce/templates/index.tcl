# $Id: index.tcl,v 3.0 2000/02/06 03:21:47 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Product Templates"]

<h2>Product Templates</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] "Product Templates"]

<hr>
<ul>
"

#
# A list of templates and their associated categories (if any)
#

set db [ns_db gethandle]
set selection [ns_db select $db "
SELECT t.template_id, t.template_name, c.category_id, c.category_name
  FROM ec_templates t, ec_category_template_map m, ec_categories c
 WHERE t.template_id = m.template_id (+)
   and m.category_id = c.category_id (+)
  ORDER BY template_name, category_name"]

set the_template_name ""
set the_template_id  ""
set the_categories   ""
proc maybe_write_a_template_line {} {
    uplevel {
	if [empty_string_p $the_template_name] { return }
	ns_write "<li><a href=\"one.tcl?template_id=$the_template_id\">$the_template_name</a> \n"
	regsub {, $} $the_categories {} the_categories
	if ![empty_string_p $the_categories] { ns_write "<br>associated with categories ($the_categories)" }
    }
}
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if {[string compare $template_name $the_template_name] != 0} {
	maybe_write_a_template_line
	set the_template_name $template_name
	set the_template_id   $template_id
	set the_categories ""
    }
    if ![empty_string_p $category_name] {
	append the_categories "<a href=\"../cat/category.tcl?[export_url_vars category_id category_name]\">$category_name</a>, "
    }
}
maybe_write_a_template_line



# For audit tables
set table_names_and_id_column [list ec_templates ec_templates_audit template_id]

ns_write "
</ul>

<p>

<h3>Actions</h3>

<ul>

<li><a href=\"/admin/ecommerce/audit-tables.tcl?[export_url_vars table_names_and_id_column]\">Audit All Templates</a>

<p>

<li><a href=\"add.tcl\">Add new template from scratch</a>
</ul>
[ad_admin_footer]
"
