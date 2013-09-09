<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id users.adp,v 1.1.1.1 2000/08/08 07:25:00 ron Exp
}
%>

<h1>User List</h1>
<hr>
<br>

<table>
<tr bgcolor=#dddddd>
<th>Name</th><th>City</th><th>State</th>
</tr>

<multiple name="lesson3.users">

<if %lesson3.users.rownum% odd>
<tr bgcolor=#ffffff>
</if>

<if %lesson3.users.rownum% even>
<tr bgcolor=#eeeeee>
</if>

<td>
<var name="lesson3.users.last_name">,
<var name="lesson3.users.first_name">
</td>

<td>
<var name="lesson3.users.city">
</td>

<td>
<var name="lesson3.users.state">
</td>

</tr>

</multiple>

</table>
