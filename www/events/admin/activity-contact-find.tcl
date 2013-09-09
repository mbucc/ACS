ad_page_contract {
    @param return_url the url to which to return after picking a contact
    @param activity_id an optional activity_id

    Asks the user to search for a default contact person

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id activity-contact-find.tcl,v 3.4.2.3 2000/09/22 01:37:35 kevin Exp
} {
    {return_url:notnull}
    {activity_id:integer,optional}
}

if {[exists_and_not_null activity_id]} {
    set export_vars_html "
    <input type=hidden name=activity_id value=$activity_id>
    <input type=hidden name=passthrough value=\"activity_id\">"
} else {
    set export_vars_html ""
}

doc_return  200 text/html "
[ad_header "Pick a Contact Person"]
<h2>Pick a Contact Person</h2>
<hr>
<form action=\"/user-search\" method=get>
<input type=hidden name=target value=\"$return_url\">
<input type=hidden name=custom_title value=\"Choose a Default Contact Person for Your Activity\">
$export_vars_html
<P>
<h3>Identify Contact Person</h3>
<p>
Search for a user to be the default contact person for your activity:<br>
<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>
<p>
<center>
<input type=submit value=\"Search for a contact person\">
</center>
</form>
<p>
[ad_footer]
"
