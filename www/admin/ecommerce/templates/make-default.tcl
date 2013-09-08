#  www/admin/ecommerce/templates/make-default.tcl
ad_page_contract {
    @param template_id
  @author
  @creation-date
  @cvs-id make-default.tcl,v 3.2.2.5 2000/09/22 01:35:04 kevin Exp
} {
    template_id:integer
}



db_1row get_template_info "select template_name, template from ec_templates where template_id=:template_id"


set page_html "[ad_admin_header "Set Default Template"]

<h2>Set Default Template</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Templates"] [list "one.tcl?template_id=$template_id" "$template_name"] "Set as Default"]

<hr>

Please confirm that you want this to become the default template that products will be displayed with
if no template has been specifically assigned to them.

<p>
<form method=post action=make-default-2>
[export_form_vars template_id]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"

doc_return  200 text/html $page_html



