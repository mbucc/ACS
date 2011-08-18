# $Id: ae.tcl,v 3.1.4.1 2000/03/17 08:22:51 mbryzek Exp $
# File: /www/intranet/customers/ae.tcl
# 
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Lets users add/modify information about our customers
# 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables 0
# group_id (if we're editing)
# return_url (optional)

set db [ns_db gethandle]
if { [exists_and_not_null group_id] } {
    set selection [ns_db 1row $db \
	    "select g.group_name, c.customer_status_id, c.note, g.short_name
               from im_customers c, user_groups g
              where c.group_id=$group_id
                and c.group_id=g.group_id"]
    set_variables_after_query
    set page_title "Edit customer"
    set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Customers"] [list "view.tcl?[export_url_vars group_id]" "One customer"] $page_title]

} else {
    set page_title "Add customer"
    set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Customers"] $page_title]
    
    set note ""
    set customer_status_id ""
    set "dp_ug.user_groups.creation_ip_address" [ns_conn peeraddr]
    set "dp_ug.user_groups.creation_user" $user_id

    set group_id [database_to_tcl_string $db "select user_group_sequence.nextval from dual"]
}

set page_body "
<form method=post action=ae-2.tcl>
[export_form_vars return_url group_id dp_ug.user_groups.creation_ip_address dp_ug.user_groups.creation_user]

[im_format_number 1] Customer name: 
<br><dd><input type=text size=45 name=dp_ug.user_groups.group_name [export_form_value group_name]>

<p>[im_format_number 2] Customer short name:
<br><dd><input type=text size=45 name=dp_ug.user_groups.short_name [export_form_value short_name]>

<p>[im_format_number 3] Status:
[im_customer_status_select $db "dp.im_customers.customer_status_id" $customer_status_id]

<p>[im_format_number 4] Notes:
<br><dd><textarea name=dp.im_customers.note rows=6 cols=45 wrap=soft>[philg_quote_double_quotes $note]</textarea>
 
<p><center><input type=submit value=\"$page_title\"></center>
</form>
"

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]