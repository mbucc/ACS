#
# /www/education/education/class/textbook-info.tcl
#
# this page allows users to see information about a given textbook
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#

#
# there is not a security check of any sort on this page because
# this never displays any confidential or secret information
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
[ad_header "Textbooks @ [ad_system_name]"]

<h2>Textbook Information</h2>

[ad_context_bar_ws_or_index [list "" "All Classes"] [list one.tcl "Class Home"] "Text Book Information"]

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

</blockquote>

[ad_footer]
"

ns_db relasehandle $db

ns_return 200 text/html $return_string
