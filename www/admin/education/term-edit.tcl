#
# /www/admin/education/term-edit.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to edit information about the given term
#

ad_page_variables {
    term_id
    term_name
    {start_date ""}
    {end_date ""}
}


#check the input
set exception_count 0
set exception_text ""

if {[empty_string_p $term_id]} {
    incr exception_count 
    append exception_text "<li>You must provide a term_id"
}

if {[empty_string_p $term_name]} {
    incr exception_count
    append exception_text "<li>You must provide a term name"
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set db [ns_db gethandle]


set return_string "
[ad_admin_header "[ad_system_name] Administration - Edit Term"]
<h2>Edit Term</h2>

[ad_context_bar_ws [list "/admin/" "Admin Home"] [list "" "Education Administration"] "Edit a Term"]

<hr>
<blockquote>

<form method=post action=\"term-edit-2.tcl\">

<table>

<tr><th align=left>Term Name
<td><input type=text name=term_name size=30 value=\"$term_name\" maxsize=100>
</tr>

<tr><th align=left>Date term begins: 
<td>[ad_dateentrywidget start_date $start_date]
</tr>

<tr><th align=left>Date term ends:
<td>[ad_dateentrywidget end_date $end_date]
</tr>
<tr>
<td colspan=2 align=center>
<input type=submit value=Continue>
</td>
</tr>
</table>
<input type=hidden name=term_id value=$term_id>
</form>

</blockquote>
[ad_admin_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string








