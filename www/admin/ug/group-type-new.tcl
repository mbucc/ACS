# File:     /admin/ug/group-type-new.tcl
ad_page_contract { 
    @cvs-id group-type-new.tcl,v 3.1.6.4 2000/09/22 01:36:15 kevin Exp
    @creation-date 22/12/99
    @author tarik@arsdigita.com
    This page is used for adding new user group.
} { 
}

doc_return  200 text/html "
[ad_admin_header "Define Group Type"]
<h2>Define Group Type</h2>
[ad_admin_context_bar [list "index" "User Groups"] "New Group Type"]
<hr>

<form method=post action=group-type-new-2>
<table>

<tr>
<th valign=top align=left>Group Type
<td><input type=text name=group_type size=20>
(no special characters; this will be part of a SQL table name)
</tr>

<tr>
<th valign=top align=left>Pretty Name
<td><input type=text name=pretty_name size=35>
(e.g., \"Hospital\")
</tr>

<tr>
<th valign=top align=left>Pretty Plural
<td><input type=text name=pretty_plural size=35>
(e.g., \"Hospitals\")
</tr>

<tr>
<th valign=top align=left>Approval Policy
<td>
<select name=approval_policy>
<option value=\"open\" selected>Open: Users can create groups of this type 
<option value=\"wait\">Wait: Users can suggest groups 
<option value=\"closed\">Closed: Only administrators can create groups 
</select>
</tr>

<tr>
<th valign=top align=left>Group Module Administration
<td>[ns_htmlselect -labels {Complete "Enabling/Disabling" None} \
	group_module_administration \
	{full enabling none} \
	none]
</tr>

</table>

<br>
<center>
<input type=submit value=\"Define\">
</center>
[ad_admin_footer]
"


