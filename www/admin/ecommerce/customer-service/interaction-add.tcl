# $Id: interaction-add.tcl,v 3.0.4.1 2000/04/28 15:08:39 carsten Exp $
set_form_variables 0
# possibly issue_id, user_identification_id

# the customer service rep must be logged on

set return_url "[ns_conn url]"

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

if { [info exists issue_id] } {
    set return_to_issue $issue_id
}
if { [info exists user_identification_id] } {
    set c_user_identification_id $user_identification_id
}

ReturnHeaders

ns_write "[ad_admin_header "New Interaction"]
<h2>New Interaction</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "New Interaction"]


<hr>

<form method=post action=interaction-add-2.tcl>
[export_form_vars issue_id return_to_issue c_user_identification_id]
<blockquote>
<table>
"

set db [ns_db gethandle]

if { [info exists user_identification_id] } {
    ns_write "<tr>
    <td>Customer:</td>
    <td>[ec_user_identification_summary $db $user_identification_id]</td>
    </tr>
    "
}

ns_write "<tr>
<td>Customer Service Rep:</td>
<td>[database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$customer_service_rep"] (if this is wrong, please <a href=\"/register.tcl?[export_url_vars return_url]\">log in</a>)</td>
</tr>
<tr>
<td>Date &amp; Time:</td>
<td>[ad_dateentrywidget open_date] [ec_timeentrywidget open_date "[ns_localsqltimestamp]"]</td>
</tr>
<tr>
<td>Inquired via:</td>
<td>
[ec_interaction_type_widget $db]
</td>
</tr>
<tr>
<td>Who initiated this inquiry?</td>
<td><select name=interaction_originator>
<option value=\"customer\">customer
<option value=\"rep\">customer service rep
</select>
</td>
</tr>
</table>
</blockquote>
"

if { ![info exists user_identification_id] } {
    ns_write "<p>
    Fill in any of the following information, which the system can use to try to identify the customer:
    <p>
    <blockquote>
    <table>
    <tr>
    <td>First Name:</td>
    <td><input type=text name=first_names size=15> Last Name: <input type=text name=last_name size=20></td>
    </tr>
    <tr>
    <td>Email Address:</td>
    <td><input type=text name=email size=30></td>
    </tr>
    <tr>
    <td>Zip Code:</td>
    <td><input type=text name=postal_code size=5 maxlength=5>
    If you fill this in, we'll determine which city/state they live in.</td>
    </tr>
    <tr>
    <td>Other Identifying Info:</td>
    <td><input type=text name=other_id_info size=30></td>
    </tr>
    </table>
    "
}

ns_write "</blockquote>

<center>
<input type=submit value=\"Continue\">
</center>

</form>

[ad_admin_footer]
"