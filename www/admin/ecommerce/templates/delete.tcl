# $Id: delete.tcl,v 3.0 2000/02/06 03:21:42 ron Exp $
set_the_usual_form_variables
# template_id

# check if this is the template that the admin has assigned as the default
# in which case they'll have to select a new default before they can delete
# this one

set db [ns_db gethandle]
set default_template_id [database_to_tcl_string $db "select default_template
from ec_admin_settings"]

if { $template_id == $default_template_id } {
    ad_return_complaint 1 "You cannot delete this template because it is the default template that 
    products will be displayed with if they are not set to be displayed with a different template.
    <p>
    If you want to delete this template, you can do so by first setting a different template to
    be the default template.  (To do this, go to a different template and click \"Make this template
    be the default template\".)"
    return
}

ReturnHeaders

ns_write "[ad_admin_header "Confirm Deletion"]

<h2>Confirm Deletion</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Templates"] "Delete Template"]

<hr>

Please confirm that you want to delete this template.  If any products are set to use this template, they will
now be displayed with the default template.

<form method=post action=delete-2.tcl>
[export_form_vars template_id]
<center>
<input type=submit value=\"Confirm\">
</center>

</form>

[ad_admin_footer]
"
