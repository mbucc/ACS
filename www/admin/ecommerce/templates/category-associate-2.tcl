#  www/admin/ecommerce/templates/category-associate-2.tcl
ad_page_contract {
    @param template_id
    @param category_id
    @param confirmed optional
    
    @author
    @creation-date
    @cvs-id category-associate-2.tcl,v 3.2.6.6 2000/09/22 01:35:03 kevin Exp
} {
    template_id:integer
    category_id:integer
    confirmed:optional
}


# see if the category_id is already in ec_category_template_map because
# then the user should be warned and also we can then do an update instead
# of an insert



if { [db_0or1row check_existence_t "select template_name as old_template from
ec_templates, ec_category_template_map m
where ec_templates.template_id = m.template_id
and m.category_id=:category_id"] ==0 } {

    # then this category_id isn't already in the map table

    db_dml insert_cat_temp_map "insert into ec_category_template_map (category_id, template_id) values (:category_id, :template_id)"

    ad_returnredirect "index.tcl"
    return
} elseif { [info exists confirmed] && $confirmed == "yes" } {
    # then the user has confirmed that they want to overwrite old mapping

    db_dml update_cat_temp_map "update ec_category_template_map set template_id=:template_id where category_id=:category_id"

    ad_returnredirect "index.tcl"
    return
}

# to get old_template


set template_name [db_string get_template_name "select template_name from ec_templates where template_id=:template_id"]
set category_name [db_string unused "select category_name from ec_categories where category_id=:category_id"]

# we have to warn the user first that the category will no longer be mapped to its previous template


set page_html "[ad_admin_header "Confirm Association"]

<h2>Confirm Association</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Templates"] [list "one.tcl?template_id=$template_id" "$template_name"] "Confirm Association"]

<hr>

This will cause $category_name to no longer be associated with its previous template, $old_template.  Continue?

<form method=post action=category-associate-2>
[ad_export_vars -form t {confirmed yes} template_id category_id]
foo
[export_form_vars template_id category_id]
[philg_hidden_input "confirmed" "yes"]

<center>
<input type=submit value=\"Yes\">
</center>
</form>

[ad_admin_footer]
"


doc_return  200 text/html $page_html