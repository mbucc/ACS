# $Id: contact-edit.tcl,v 3.1 2000/03/09 00:01:33 scott Exp $
set_the_usual_form_variables

# user_id

if [info exists user_id_from_search] {
    set user_id $user_id_from_search
}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select first_names, last_name from users where user_id = $user_id"]

if [empty_string_p $selection] {
    ad_return_complaint 1 "<li>We couldn't find user #$user_id; perhaps this person was nuke?"
    return
}

set_variables_after_query

append whole_page "[ad_admin_header "Contact information  for $first_names $last_name"]

<h2>Contact information for $first_names $last_name</h2>

"

append whole_page "<p>

[ad_admin_context_bar [list "index.tcl" "Users"] [list "one.tcl?[export_url_vars user_id]" "One User"] "Demographic Information"]


<hr>

"
set selection [ns_db 0or1row $db "select * from users_contact where user_id = $user_id"]

if {![empty_string_p $selection]} {
    set_variables_after_query
} else {
    set ha_state ""
    set ha_country_code ""
    set wa_state ""
    set wa_country_code ""
}



append whole_page "
<form action=contact-edit-2.tcl method=post>
[export_form_vars user_id]
<table>
<tr><th align=right>Home phone</th><td><input type=text name=home_phone [export_form_value home_phone]></td></tr>
<tr><th align=right>Work phone</th><td><input type=text name=work_phone [export_form_value work_phone]></td></tr>
<tr><th align=right>Cell phone</th><td><input type=text name=cell_phone [export_form_value cell_phone]></td></tr>
<tr><th align=right>Pager</th><td>
<input type=text name=pager [export_form_value pager]></td></tr>
<tr><th align=right>Fax</th><td>
<input type=text name=fax [export_form_value fax]></td></tr>
<tr><th align=right>Aim Screen Name</th>
<td><input type=text name=aim_screen_name [export_form_value aim_screen_name]></td></tr>
<tr><th align=right>ICQ Number</th>
<td><input type=text name=icq_number [export_form_value cell_phone]></td></tr>
<tr><th align=right valign=top>Home address</th>
<td><input type=text name=ha_line1 [export_form_value ha_line1]><br>
<input type=text name=ha_line2 [export_form_value ha_line2]><br>
</td></tr>
<tr><th align=right>Home City</th><td><input type=text name=ha_city [export_form_value ha_city]></td></tr>
<tr><th align=right>Home State</th><td>
[state_widget $db $ha_state ha_state]
</td></tr>
<tr><th align=right>Home Country</th><td>
[country_widget $db $ha_country_code ha_country_code]
</td></tr>
<tr><th align=right>Home Postal Code</th><td>
<input type=text name=ha_postal_code [export_form_value ha_postal_code]>
<tr><th align=right>Work City</th><td><input type=text name=wa_city [export_form_value ha_city]></td></tr>
<tr><th align=right>Work State</th><td>[state_widget $db $wa_state wa_state]</td></tr>
<tr><th align=right>Work Postal Code</th><td><input type=text name=wa_postal_code [export_form_value wa_postal_code]></td></tr>
<tr><th align=right>Work Country</th><td>
[country_widget $db $wa_country_code wa_country_code]
</td></tr>
</table>

<center>
<input type=submit name=submit value=Submit>
</center>
</form>

[ad_admin_footer]
"


ns_db releasehandle $db
ns_return 200 text/html $whole_page
