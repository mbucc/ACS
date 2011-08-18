# $Id: add-alert-2.tcl,v 3.1.2.1 2000/03/15 05:03:48 curtisg Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# domain_id, frequency,  howmuch

set db [gc_db_gethandle]

set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

set alert_id [database_to_tcl_string $db "select classified_email_alert_id_seq.nextval from dual"]

append html "[gc_header "Add Alert (Form 2)"]

<h2>Add an Alert</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Add Alert, Step 2"]

<form method=POST action=\"add-alert-3.tcl\">
[export_form_vars alert_id domain_id frequency howmuch]

<table>
<tr>
<td><input name=alert_type type=radio value=all></td><td>Ask for
all new ads</td>
<td></td>
</tr>

<tr>
<td><input name=alert_type type=radio
value=category></td><td>Choose a category</td>
<td><select name=primary_category>
<option>Choose a Category
"

set selection [ns_db select $db "select primary_category,
upper(primary_category)
from ad_categories
where domain_id = $domain_id
order by 2"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append page_content  "<option>$primary_category\n"
}

append html "</select></td>
</tr>

<tr valign=top>
<td><input name=alert_type type=radio value=keywords></td><td
width=45%>Any ad with the following keywords (separated by
spaces):</td>
<td valign=bottom><input type=text size=30
name=query_string></td>
</tr>

</table>

<p>
<center>
<input type=submit value=\"Add This Alert\">
</center>

</form>
"

ns_return 200 text/html $html
