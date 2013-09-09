#  www/admin/ecommerce/templates/add-2.tcl
ad_page_contract {
    @param template the template
    @param template_name the name of the template

  @author
  @creation-date
  @cvs-id add-2.tcl,v 3.2.2.7 2001/01/12 19:32:05 khy Exp
} {
    template_name
    template:allhtml

}


set exception_count 0
set exception_text ""



if { ![info exists template] || [empty_string_p $template] } {
    incr exception_count
    append exception_text "<li>You forgot to enter anything into the ADP template box.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

if {[fm_adp_function_p $template]} {
    doc_return  200 text/html "
    <P><tt>We're sorry, but files added here cannot
    have functions in them for security reasons. Only HTML and 
    <%= \$variable %> style code may be used.</tt>"
    return
}



set page_html "[ad_admin_header "Confirm Template"]

<h2>Confirm Template</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Templates"] "Confirm Template"]

<hr>
"


set template_id [db_string get_template_nextval "select ec_template_id_sequence.nextval from dual"]

append page_html "<form method=post action=add-3>
[export_form_vars template_name template]
[export_form_vars -sign template_id]
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
db_release_unused_handles
doc_return 200 text/html $page_html
