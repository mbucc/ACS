#
# /www/admin/education/textbook-info.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this lists all of the textbooks used by the system
#

ad_page_variables {
    textbook_id
}

if {[empty_string_p $textbook_id]} {
    ad_return_complaint 1 "<li>You must provide a textbook identification number.
    return
}


set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select title, author, publisher, isbn from edu_textbooks where textbook_id = $textbook_id"]

if {$selection == ""} {
    ad_return_complaint 1 "<li>The textbook identification number you have provided is not valid."
    return
} else {
    set_variables_after_query
}


set return_string "
[ad_admin_header "Textbooks @ [ad_system_name]"]

<h2>Textbook Information</h2>

[ad_context_bar_ws [list "/admin/" "Admin Home"] [list "" "Education Administration"] [list "textbooks.tcl" Textbooks] "One Textbook"]

<hr>
<blockquote>

<table>

<tr>
<th align=left>Title:</td>
<td>$title
</tr>

<tr>
<th align=left>Author:</td>
<td>$author
</tr>

<tr>
<th align=left>Publisher:</td>
<td>$publisher
</tr>

<tr>
<th align=left>ISBN:</td>
<td>$isbn
</tr>
</table>

<p>
<a href=\"textbook-delete.tcl?textbook_id=$textbook_id\">Delete this textbook</a>
<p>
</blockquote>

[ad_admin_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string

