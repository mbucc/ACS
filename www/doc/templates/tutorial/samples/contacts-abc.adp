<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id contacts-abc.adp,v 1.1.1.1 2000/08/08 07:25:00 ron Exp
}
%>

<h1>ABC Company Contacts</h1>
<hr>
<br>

<multiple name="contacts">

<var name="contacts.rownum">.
<var name="contacts.first_name"> 
<var name="contacts.last_name">
<blockquote>
<var name="contacts.address1"><br>

<if %contacts.address2% not nil>
<var name="contacts.address2"><br>
</if>

<var name="contacts.city">,
<var name="contacts.state">

</blockquote>

</multiple>

<br><br>
<hr>
Karl Goldstein 
(<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>)
<br>
Report generated on 
<%= [ns_httptime [file mtime [ns_url2file [ns_conn url]]]] %>

