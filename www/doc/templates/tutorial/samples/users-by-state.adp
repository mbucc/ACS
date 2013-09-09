<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id users-by-state.adp,v 1.1.1.1 2000/08/08 07:25:00 ron Exp
}
%>

<h1>User List</h1>
<hr>
<br>

<table>
<tr bgcolor=#dddddd>
<th>Name</th><th>City</th><th>State</th>
</tr>

<multiple name="users">

<tr>

<td>
  <var name="users.last_name">,
  <var name="users.first_name">
</td>

<td>
  <var name="users.city">
</td>

<td>
  <if %users.state% ne %Last.state%>
    <var name="users.state">
  </if>
  <else>
    &nbsp;
  </else>
</td>

</tr>

</multiple>

</table>
