# /www/gc/admin/domain-administrator-update.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id domain-administrator-update.tcl,v 3.2.6.6 2000/09/22 01:37:59 kevin Exp
    
    @param domain_id

} {
    domain_id:integer
}


db_1row gc_admin_update_domain_admin_get {
    select ad_domains.*, users.email 
    from ad_domains, users
    where domain_id = :domain_id
    and users.user_id(+) = ad_domains.primary_maintainer_id
} 


set action "Edit administrator for $domain"

append html "[ad_header "$action"]

<h2>$action</h2>

in <a href=\"index\">[neighbor_system_name] administration</a>
<hr>

<form action=\"/user-search\" method=post>
[export_form_vars domain_id]
<input type=hidden name=target value=\"/admin/gc/domain-administrator-update-2.tcl\">
<input type=hidden name=passthrough value=\"domain_id\">
<input type=hidden name=custom_title value=\"Choose a Member for the Administrator of $domain classifieds\">

<h3></h3>
<p>
Search for a user to be primary administrator of this domain by<br>
<table border=0>
<tr><td>Email address:<td><input type=text name=email  size=40 [export_form_value email]></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>

<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars category_id]
</form>
[neighbor_footer]
"

db_release_unused_handles
doc_return  200 text/html $html


