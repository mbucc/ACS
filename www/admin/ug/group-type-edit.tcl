# $Id: group-type-edit.tcl,v 3.0 2000/02/06 03:29:11 ron Exp $
# File:     /admin/ug/group-type-edit.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  editing user group type properties

set_the_usual_form_variables

# group_type

set db [ns_db gethandle]

set selection [ns_db 1row $db "select * from user_group_types where group_type = '$QQgroup_type'"]
set group_type_module_id [database_to_tcl_string $db "
select group_type_modules_id_sequence.nextval from dual"]

set_variables_after_query

ns_return 200 text/html "
[ad_admin_header "Edit $pretty_name"]
<h2>Edit $pretty_name</h2>
one of <a href=\"index.tcl\">the group types</a> in 
<a href=\"/admin\">[ad_system_name] administration</a> 
<hr>

<blockquote>
<form method=POST action=\"group-type-edit-2.tcl\">
[export_form_vars group_type group_type_module_id]

<table>
<tr>
  <th valign=top align=left>Pretty Name
  <td><input type=text name=pretty_name size=20 value=\"[philg_quote_double_quotes $pretty_name]\">
</tr>
<tr>
  <th valign=top align=left>Plural Version of Name
  <td><input type=text name=pretty_plural size=20 value=\"[philg_quote_double_quotes $pretty_plural]\">
</tr>
<tr>
<th valign=top align=left>Approval Policy
<td>[ns_htmlselect -labels { "Open: Users can create groups of this type" \
	"Wait: Users can suggest groups" \
	"Closed: Only administrators can create groups" }\
	approval_policy {open wait closed} $approval_policy]
</tr>

<tr>
<th valign=top align=left>Default New Member Policy
<td>[eval "ns_htmlselect -labels \{\"Open: Users will be able to join $pretty_plural\" \
	\"Wait: Users can apply to join $pretty_plural\" \
	\"Closed: Only administrators can put users in $pretty_plural\" \} \
	default_new_member_policy \{open wait closed\} $default_new_member_policy"]
</tr>

<tr>
<th valign=top align=left>Group Module Administration
<td>[ns_htmlselect -labels {Complete "Enabling/Disabling" None} \
	group_module_administration \
	{full enabling none} \
	$group_module_administration]
</tr>

</table>

<p>
<center>
<input type=submit value=\"Update\">
</center>
</blockquote>
[ad_admin_footer]
"
