# $Id: category-associate-2.tcl,v 3.0.4.1 2000/04/28 15:08:57 carsten Exp $
set_the_usual_form_variables
# template_id, category_id

# see if the category_id is already in ec_category_template_map because
# then the user should be warned and also we can then do an update instead
# of an insert

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select template_name as old_template from
ec_templates, ec_category_template_map m
where ec_templates.template_id = m.template_id
and m.category_id=$category_id"]

if { [empty_string_p $selection] } {
    # then this category_id isn't already in the map table

    ns_db dml $db "insert into ec_category_template_map (category_id, template_id) values ($category_id, $template_id)"

    ad_returnredirect "index.tcl"
    return
} elseif { [info exists confirmed] && $confirmed == "yes" } {
    # then the user has confirmed that they want to overwrite old mapping

    ns_db dml $db "update ec_category_template_map set template_id=$template_id where category_id=$category_id"

    ad_returnredirect "index.tcl"
    return
}

# to get old_template
set_variables_after_query

set template_name [database_to_tcl_string $db "select template_name from ec_templates where template_id=$template_id"]
set category_name [database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]

# we have to warn the user first that the category will no longer be mapped to its previous template
ReturnHeaders

ns_write "[ad_admin_header "Confirm Association"]

<h2>Confirm Association</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Templates"] [list "one.tcl?template_id=$template_id" "$template_name"] "Confirm Association"]

<hr>

This will cause $category_name to no longer be associated with its previous template, $old_template.  Continue?

<form method=post action=category-associate-2.tcl>
[export_form_vars template_id category_id]
[philg_hidden_input "confirmed" "yes"]

<center>
<input type=submit value=\"Yes\">
</center>
</form>

[ad_admin_footer]
"
