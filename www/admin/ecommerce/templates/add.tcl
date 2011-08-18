# $Id: add.tcl,v 3.0 2000/02/06 03:21:37 ron Exp $
set_form_variables 0
# possibly based_on

ReturnHeaders

ns_write "[ad_admin_header "Add a Template"]

<h2>Add a Template</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Templates"] "Add a Template"]

<hr>
"

if { [info exists based_on] && ![empty_string_p $based_on] } {
    set db [ns_db gethandle]
    set template [database_to_tcl_string $db "select template from ec_templates where template_id=$based_on"]
} else {
    set template ""
}

ns_write "<form method=post action=add-2.tcl>

Name: <input type=text name=template_name size=30>

<p>

ADP template:<br>
<textarea name=template rows=10 cols=60>$template</textarea>

<p>

<center>
<input type=submit value=\"Submit\">
</center>

</form>

[ad_admin_footer]
"
