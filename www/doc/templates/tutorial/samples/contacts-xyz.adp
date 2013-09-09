<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id contacts-xyz.adp,v 1.1.1.1 2000/08/08 07:25:00 ron Exp
}
%>

<h1>XYZ Company Contacts</h1>
<hr>
<br>

<table cellspacing=0 cellpadding=2 border=1>
<tr bgcolor=#eeeeee>
<th>Name</th><th>Address 1</th><th>Address 2</th><th>City</th><th>State</th>
</tr>

<multiple name="contacts">

<tr>

<td>&nbsp;
<var name="contacts.last_name">,
<var name="contacts.first_name">
</td>

<td>&nbsp;
<var name="contacts.address1">
</td>

<td>&nbsp;
<var name="contacts.address2">
</td>

<td>&nbsp;
<var name="contacts.city">
</td>

<td>&nbsp;
<var name="contacts.state">
</td>

</tr>

</multiple>

</table>
<br><br>
<hr>
Karl Goldstein 
(<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>)
<br>
Report generated on 
<%= [ns_httptime [file mtime [ns_url2file [ns_conn url]]]] %>

