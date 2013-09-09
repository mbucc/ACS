# /www/gc/add-alert-2.tcl
ad_page_contract {
    Allows user to specify an email alert to receive for certain classified ads.

    @author xxx
    @date unknown
    @cvs-id add-alert-2.tcl,v 3.4.6.5 2001/01/10 18:58:32 khy Exp
} {
    domain_id
    frequency
    howmuch
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

db_1row gc_query_for_domain_info [gc_query_for_domain_info $domain_id]

set alert_id [db_string classified_ad_alert_seq_nextval_query "select classified_email_alert_id_seq.nextval from dual"]

append html "[gc_header "Add Alert (Form 2)"]

<h2>Add an Alert</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Add Alert, Step 2"]

<form method=POST action=\"add-alert-3\">
[export_form_vars -sign alert_id]
[export_form_vars domain_id frequency howmuch]

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

db_foreach primary_category_query "
     select
       primary_category,
       upper(primary_category)
     from ad_categories
     where domain_id = :domain_id
     order by 2
" -bind [ad_tcl_vars_to_ns_set domain_id] {
    append html  "<option>$primary_category\n"
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



doc_return  200 text/html $html




