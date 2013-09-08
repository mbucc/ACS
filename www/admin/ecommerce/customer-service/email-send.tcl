# email-send.tcl

ad_page_contract { 
    @param issue_id
    @param user_identification_id

    @author
    @creation-date
    @cvs-id email-send.tcl,v 3.2.6.6 2000/09/22 01:34:51 kevin Exp
} {
    issue_id
    user_identification_id

}


set return_url "[ad_conn url]?[export_entire_form_as_url_vars]"

set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}


set page_title "Send Email to Customer"
append doc_body "[ad_admin_header $page_title]
<h2>$page_title</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] $page_title]

<hr>
"

# make sure this user_identification_id has an email address associated with it



db_1row get_user_information "select u.email as user_email, id.email as id_email
from users u, ec_user_identification id
where id.user_id = u.user_id(+)
and id.user_identification_id=:user_identification_id
"


if { ![empty_string_p $user_email] } {
    set email_to_use $user_email
} else {
    set email_to_use $id_email
}

if { [empty_string_p $email_to_use] } {
    append doc_body "
    
    Sorry, we don't have the customer's email address on file.
    
    [ad_admin_footer]
    "
    return
}

# generate action_id here for double-click protection
set action_id [db_string get_new_action_id "select ec_action_id_sequence.nextval from dual"]

append doc_body "If you are not [db_string get_full_name "select first_names || ' ' || last_name from users where user_id=:customer_service_rep"], please <a href=\"/register?[export_url_vars return_url]\">log in</a>

<form name=email_form method=post action=/tools/spell>
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
<td>[ec_canned_response_selector email_form message]</td>
</tr>
</table>

<p>

<center>
<input type=submit value=\"Send\">
</center>

</form>
[ad_admin_footer]
"



doc_return  200 text/html $doc_body


