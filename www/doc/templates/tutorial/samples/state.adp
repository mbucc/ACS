<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id state.adp,v 1.1.1.1 2000/08/08 07:25:00 ron Exp
}
%>

<h1>Users in <var name="state"></h1>
<hr>
<br>

<if %lesson4.users.rowcount% eq 0>
Sorry, there are no users in <var name="state">.
</if>

<if %lesson4.users.rowcount% gt 0>

<table>
<tr>
<th>First Name</th><th>Last Name</th><th>City</th><th>State</th>
</tr>

<multiple name="lesson4.users">

<tr>
<td>
<var name="lesson4.users.last_name">,
<var name="lesson4.users.first_name">
</td>

<td>
<var name="lesson4.users.city">
</td>

<td>
<var name="lesson4.users.state">
</td>

</tr>

</multiple>

</table>

</if>