<%=[ad_admin_header "Define Group Type"]%>

<h2>Define Group Type</h2>

<%=[ad_admin_context_bar [list "index" "User Groups"] "New Group Type"]%>

<hr>

<form method=post action=group-type-new-2>
<table>
<tr>
<th>Group type
<td><input type=text name=group_type size=20>
(no special characters; this will be part of a SQL table name)
</tr>
<tr>
<th>Pretty Name
<td><input type=text name=pretty_name size=35>
(e.g., "Hospital")
</tr>
<tr>
<th>Pretty Plural
<td><input type=text name=pretty_plural size=35>
(e.g., "Hospitals")
</tr>
<tr>
<th>Approval Policy
<td>
<select name=approval_policy>
<option value="open" selected>Open: Users can create groups of this type 
<option value="wait">Wait: Users can suggest groups 
<option value="closed">Closed: Only administrators can create groups 
</select>
</tr>
</table>
<br>
<center>
<input type=submit value="Define">
</center>



<%=[ad_admin_footer]%>

