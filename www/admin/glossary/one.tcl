# $Id: one.tcl,v 3.0.4.1 2000/04/28 15:09:06 carsten Exp $
set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}

set_the_usual_form_variables
# term

if { ![info exists term] || [empty_string_p $QQterm] } {
    ad_return_complaint 1 "No term given"
    return
}

ReturnHeaders
ns_write "[ad_admin_header $term]

<h2>$term</h2>

[ad_admin_context_bar [list "index.tcl" Glossary] "One Term"]

<hr>

<i>$term</i>:
"

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select definition, approved_p from glossary where term = '$QQterm'"]

if { $selection == "" } {
    set definition "Not defined in glossary."
    set approved_p 't'
} else {
    set_variables_after_query
}

ns_write "
<blockquote>$definition</blockquote>
<ul>
<li><a href=\"term-edit.tcl?term=[ns_urlencode $term]\">Edit this Term</a>
<p>
<li><a href=\"term-delete.tcl?term=[ns_urlencode $term]\">Delete this Term (immediate)</a>
"

if { $approved_p == "f" } {
    ns_write "<li><a href=\"term-approve.tcl?term=[ns_urlencode $term]\">Approve this Term</a>\n"
}

ns_write "
</ul>

[ad_admin_footer]
"