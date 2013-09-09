#/admin/ug/group-type-edit.tcl

ad_page_contract {
    @param group_type the type of group
    
    @cvs-id group-type-edit.tcl,v 3.1.6.6 2000/09/22 01:36:14 kevin Exp
    @author tarik@arsdigita.com
    @creation-date 22 December 1999
} {
    group_type:notnull
}


db_1row get_ugt "select pretty_name, pretty_plural, approval_policy, default_new_member_policy, group_module_administration from user_group_types where group_type = :group_type"
set group_type_module_id [db_string get_gtmidseq "
select group_type_modules_id_sequence.nextval from dual"]



doc_return  200 text/html "
[ad_admin_header "Edit $pretty_name"]
<h2>Edit $pretty_name</h2>
one of <a href=\"index\">the group types</a> in 
<a href=\"/admin\">[ad_system_name] administration</a> 
<hr>

<blockquote>
<form method=POST action=\"group-type-edit-2\">
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

