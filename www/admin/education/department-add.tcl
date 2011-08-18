#
# /www/admin/education/department-add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to add a new department to the system
#


set return_string "
[ad_admin_header "[ad_system_name] Administration - Add a Department"]
<h2>Add a Department</h2>

[ad_context_bar_ws [list "/admin/" "Admin Home"] [list "" "[ad_system_name] Administration"] "Add a Department"]

<hr>
<blockquote>

<form method=post action=\"department-add-2.tcl\">

<table>

<tr>
<th align=left>
Department Name
</td>
<td>
<input type=text name=group_name size=40 maxsize=100>
</td>
</tr>

<tr>
<th align=left>
Department Number
</td>
<td>
<input type=text name=department_number size=20 maxsize=100>
</td>
</tr>

<tr>
<th align=left>
External Homepage URL
</td>
<td>
<input type=text name=external_homepage_url value=\"http://\" size=40 maxsize=200>
</td>
</tr>

<tr>
<th align=left>
Mailing Address
</td>
<td>
<input type=text name=mailing_address size=40 maxsize=200>
</td>
</tr>


<tr>
<th align=left>
Phone Number
</td>
<td>
<input type=text name=phone_number size=15 maxsize=20>
</td>
</tr>

<tr>
<th align=left>
Fax Number
</td>
<td>
<input type=text name=fax_number size=15 maxsize=20>
</td>
</tr>

<tr>
<th align=left>
Inquiry Email Address
</td>
<td>
<input type=text name=inquiry_email size=25 maxsize=50>
</td>
</tr>


<tr>
<th align=left valign=top>
Description
</td>
<td>
<textarea wrap cols=45 rows=5 name=description></textarea>
</td>
</tr>


<tr>
<th align=left valign=top>
Mission Statement
</td>
<td>
<textarea wrap cols=45 rows=5 name=mission_statement></textarea>
</td>
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

ns_return 200 text/html $return_string









