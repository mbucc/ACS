# $Id: domain-add.tcl,v 3.1 2000/03/11 00:45:11 curtisg Exp $

set db [ns_db gethandle]
set domain_id [database_to_tcl_string $db "select ad_domain_id_seq.nextval from dual"]
ns_db releasehandle $db

ns_return 200 text/html "[ad_admin_header "Add a domain"]

<h2>Add domain</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] "Add domain"]

<hr>

<form method=post action=/user-search.tcl>
[export_form_vars domain_id]
<input type=hidden name=target value=\"/admin/gc/domain-add-2.tcl\">
<input type=hidden name=passthrough value=\"domain_id full_noun domain\">
<input type=hidden name=custom_title value=\"Choose a Member to Add as an Administrator\">

<H3>Identity</H3>
<table>
<tr><td>Full domain name:<td><input type=text name=full_noun></tr>
<tr><td>Pick a short key:<td><input type=text name=domain></tr>
</table>
<h3>Administration</h3>
Search for a user to be primary administrator of this domain by<br>
<table border=0>
<tr><td>Email address:<td><input type=text name=email  size=40 [export_form_value email]></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>

<p>

<center>
<input type=submit name=submit value=\"Proceed\">
</center>

</form>
[ad_admin_footer]
"
