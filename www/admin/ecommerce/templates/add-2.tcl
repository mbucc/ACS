# $Id: add-2.tcl,v 3.0 2000/02/06 03:21:34 ron Exp $
set_the_usual_form_variables
# template_name, template

set exception_count 0
set exception_text ""

if { ![info exists template_name] || [empty_string_p $template_name] } {
    incr exception_count
    append exception_text "<li>You forgot to enter a template name.\n"
}

if { ![info exists template] || [empty_string_p $template] } {
    incr exception_count
    append exception_text "<li>You forgot to enter anything into the ADP template box.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ReturnHeaders

ns_write "[ad_admin_header "Confirm Template"]

<h2>Confirm Template</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Templates"] "Confirm Template"]

<hr>
"

set db [ns_db gethandle]
set template_id [database_to_tcl_string $db "select ec_template_id_sequence.nextval from dual"]

ns_write "<form method=post action=add-3.tcl>
[export_form_vars template_id template_name template]


Name: 

<p>

<blockquote>
<pre>$template_name</pre>
</blockquote>

<p>

ADP template:

<p>

<blockquote>
<pre>
[ns_quotehtml $template]
</pre>
</blockquote>

<p>

<center>
<input type=submit value=\"Confirm\">
</center>

</form>

[ad_admin_footer]
"
