ad_page_contract {
    Finds a particular user for permissioning purposes.

    @author mark@ciccarello.com
    @creation-date February 2000
    @cvs-id find-user.tcl,v 3.4.2.2 2000/07/21 03:57:24 ron Exp
} {
    table_name:notnull
    row_id:notnull
}

set html "[ad_admin_header  "Edit Permissions for a User" ]
<h2>Add or Edit Permissions for a User</h2>
<hr>
<p>
"

set custom_title "Edit Permissions for User"
set target "/admin/gp/one-user.tcl"
set passthrough [list table_name row_id]

append html "</table>"
append html "<h3>Edit permissions for user:</h3>
<form action=\"/user-search\" method=post>
[export_form_vars passthrough custom_title target table_name row_id]
<table>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>
<input type=submit value=\"Search\">
</form>
[ad_admin_footer]
"

ad_return_top_of_page $html
