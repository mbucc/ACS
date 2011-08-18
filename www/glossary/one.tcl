# $Id: one.tcl,v 3.0 2000/02/06 03:45:05 ron Exp $
# get the user id in case the person is logged in and we want to offer
# an edit option
set user_id [ad_get_user_id]

set_the_usual_form_variables
# term

if { ![info exists term] || [empty_string_p $term] } {
    ad_return_complaint 1 "No term given"
    return
}

ReturnHeaders

ns_write "[ad_header $term]

<h2>$term</h2>

[ad_context_bar_ws_or_index [list "index.tcl" Glossary] "One Term"]

<hr>

<i>$term</i>:
"

set db [ns_db gethandle]

set definition [database_to_tcl_string_or_null $db "select definition from glossary where term = '$QQterm'"]

if { $definition == "" } {
    set definition "Not defined in glossary."
}

ns_db releasehandle $db

ns_write "
<blockquote>$definition</blockquote>
[ad_footer]
"
