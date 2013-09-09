# /www/intranet/customers/ae.tcl

ad_page_contract {
    Lets users add/modify information about our customers

    @param group_id if specified, we edit the customer with this group_id
    @param return_url Return URL

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000
    @cvs-id ae.tcl,v 3.9.2.12 2001/01/12 17:18:31 khy Exp

} {
    { group_id:integer "" }
    { return_url "" }
}

set user_id [ad_maybe_redirect_for_registration]

if { ![empty_string_p $group_id] } {
    if { ![db_0or1row customer_get_info \
	    "select g.group_name, c.customer_status_id, c.customer_type_id, c.billable_p,
                    c.note, g.short_name, c.annual_revenue, c.referral_source,
                    nvl(c.manager,$user_id) as manager, 
                    c.site_concept, nvl(c.contract_value,600) as contract_value,
                    to_char(nvl(c.start_date,sysdate),'YYYY-MM-DD') as start_date
               from im_customers c, user_groups g
              where c.group_id=:group_id
                and c.group_id=g.group_id" ] } {
		  
        ad_return_error "Customer #group_id doesn't exist" "Please back up, and try again"
        return
    }

    set page_title "Edit customer"
    set context_bar [ad_context_bar_ws [list index "Customers"] [list "view?[export_url_vars group_id]" "One customer"] $page_title]

} else {
    set page_title "Add customer"
    set context_bar [ad_context_bar_ws [list index "Customers"] $page_title]

    # Grab today's date
    set start_date [lindex [split [ns_localsqltimestamp] " "] 0]
    set note ""
    set customer_status_id ""
    set customer_type_id ""
    set annual_revenue ""
    set referral_source ""
    set billable_p "f"
    set "dp_ug.user_groups.creation_ip_address" [ns_conn peeraddr]
    set "dp_ug.user_groups.creation_user" $user_id

    set group_id [db_nextval "user_group_sequence"]
}

set customer_defaults [ns_set create]
ns_set put $customer_defaults dp.im_customers.billable_p $billable_p

set page_body "
<form method=get action=ae-2>
[export_form_vars return_url dp_ug.user_groups.creation_ip_address dp_ug.user_groups.creation_user]
[export_form_vars -sign group_id]

[im_format_number 1] Customer name: 
<br><dd><input type=text size=45 name=dp_ug.user_groups.group_name [export_form_value group_name]>

<p>[im_format_number 2] Customer short name:
<br><dd><input type=text size=45 name=dp_ug.user_groups.short_name [export_form_value short_name]>

<p>[im_format_number 3] Referral Source:
<br><dd><input type=text size=45 name=dp.im_customers.referral_source [export_form_value referral_source]>

<p>[im_format_number 4] Status:
[im_customer_status_select "dp.im_customers.customer_status_id" $customer_status_id]

<p>[im_format_number 5] Customer Type:
[im_customer_type_select "dp.im_customers.customer_type_id" $customer_type_id]

<p>[im_format_number 6] Annual Revenue:
[im_category_select "Intranet Annual Revenue" "dp.im_customers.annual_revenue.money" $annual_revenue]

<p>[im_format_number 7] Is this a billable customer?
[bt_mergepiece "
<dd><input type=radio name=dp.im_customers.billable_p value=t> Yes &nbsp;&nbsp; 
    <input type=radio name=dp.im_customers.billable_p value=f> No
" $customer_defaults]

<p>[im_format_number 8] Notes:
<br><dd><textarea name=dp.im_customers.note rows=6 cols=45 wrap=soft>[philg_quote_double_quotes $note]</textarea>

<p>[im_format_number 9] Project Start Date (estimated):
<br><dd>[philg_dateentrywidget start $start_date]

<p>[im_format_number 10] Contract Value (in \$K):
<br><dd><input type=text name=dp.im_customers.contract_value.money size=11 maxlength=10 [export_form_value contract_value]>

<p>[im_format_number 11] Site Concept (one-line description):
<br><dd><input type=text name=dp.im_customers.site_concept size=80 maxlength=80 [export_form_value site_concept]>

<p>[im_format_number 12] Client Services Manager:
<br><dd>
<select name=dp.im_customers.manager size=8>
<option value=\"\"> -- Please Select --
[im_employee_select_optionlist [value_if_exists manager]]
</select>

<p><center><input type=submit value=\"$page_title\"></center>
</form>
"

doc_return  200 text/html [im_return_template]
