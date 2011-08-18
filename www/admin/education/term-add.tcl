#
# /www/admin/education/term-add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to add a term to the system
#

# this does not expect any arguments

set db [ns_db gethandle]


set return_string "
[ad_admin_header "[ad_system_name] Administration - Add a Term"]
<h2>Add a Term</h2>

[ad_context_bar_ws [list "/admin/" "Admin Home"] [list "" "Education Administration"] "Add a Term"]

<hr>
<blockquote>

<form method=post action=\"term-add-2.tcl\">

<table>

<tr><th align=left>Term Name
<td><input type=text name=term_name size=30 maxsize=100>
</tr>

<tr><th align=left>Date term begins: 
<td>[ad_dateentrywidget start_date]
</tr>

<tr><th align=left>Date term ends:
<td>[ad_dateentrywidget end_date [database_to_tcl_string $db "select add_months(sysdate,6) from dual"]]
</tr>
<tr>
<td colspan=2 align=center>
<input type=submit value=Continue>
</td>
</tr>
</table>
</form>

</blockquote>
[ad_admin_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string








