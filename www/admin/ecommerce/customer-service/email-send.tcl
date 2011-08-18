# $Id: email-send.tcl,v 3.0.4.1 2000/04/28 15:08:38 carsten Exp $
set_the_usual_form_variables
# issue_id, user_identification_id

set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

ReturnHeaders
set page_title "Send Email to Customer"
ns_write "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>
"

# make sure this user_identification_id has an email address associated with it

set db [ns_db gethandle]

set selection [ns_db 1row $db "select u.email as user_email, id.email as id_email
from users u, ec_user_identification id
where id.user_id = u.user_id(+)
and id.user_identification_id=$user_identification_id
"]
set_variables_after_query

if { ![empty_string_p $user_email] } {
    set email_to_use $user_email
} else {
    set email_to_use $id_email
}

if { [empty_string_p $email_to_use] } {
    ns_write "
    
    Sorry, we don't have the customer's email address on file.
    
    [ad_admin_footer]
    "
    return
}

# generate action_id here for double-click protection
set action_id [database_to_tcl_string $db "select ec_action_id_sequence.nextval from dual"]

ns_write "If you are not [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$customer_service_rep"], please <a href=\"/register.tcl?[export_url_vars return_url]\">log in</a>

<form name=email_form method=post action=/tools/spell.tcl>
[philg_hidden_input var_to_spellcheck "message"]
[philg_hidden_input target_url "/admin/ecommerce/customer-service/email-send-2.tcl"]
[export_form_vars email_to_use action_id issue_id customer_service_rep user_identification_id]
<table>
<tr>
<td align=right><b>From</td>
<td>[ad_parameter CustomerServiceEmailAddress ecommerce]</td>
</tr>
<tr>
<td align=right><b>To</td>
<td>$email_to_use</td>
</tr>
<tr>
<td align=right><b>Cc</td>
<td><input type=text name=cc_to size=30></td>
</tr>
<tr>
<td align=right><b>Bcc</td>
<td><input type=text name=bcc_to size=30></td>
</tr>
<tr>
<td align=right><b>Subject</td>
<td><input type=text name=subject size=30></td>
</tr>
<tr>
<td align=right><b>Message</td>
<td><textarea wrap name=message rows=10 cols=50></textarea></td>
</tr>
<tr>
<td align=right><b>Canned Responses</td>
<td>[ec_canned_response_selector $db email_form message]</td>
</tr>
</table>

<p>

<center>
<input type=submit value=\"Send\">
</center>

</form>
[ad_admin_footer]
"