# $Id: ae.tcl,v 3.2.2.1 2000/03/17 08:23:05 mbryzek Exp $
# File: /www/intranet/partners/ae.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
# 
# Purpose: Add/edit partner information
#
set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables 0
# group_id (if we're editing)
# return_url (optional)

set db [ns_db gethandle]
if { [exists_and_not_null group_id] } {
    set selection [ns_db 1row $db \
	    "select g.group_name, g.short_name, p.*
               from im_partners p, user_groups g
              where p.group_id=$group_id
                and p.group_id=g.group_id"]
    set_variables_after_query
    set page_title "Edit partner"
    set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Partners"] [list "view.tcl?[export_url_vars group_id]" "One partner"] $page_title]

} else {
    set page_title "Add partner"
    set context_bar [ad_context_bar [list "/" Home] [list "../" "Intranet"] [list index.tcl "Partners"] $page_title]
    set "dp_ug.user_groups.creation_ip_address" [ns_conn peeraddr]
    set "dp_ug.user_groups.creation_user" $user_id
    set group_id [database_to_tcl_string $db "select user_group_sequence.nextval from dual"]
}

set page_body "
<form method=post action=ae-2.tcl>
[export_form_vars return_url group_id dp_ug.user_groups.creation_ip_address dp_ug.user_groups.creation_user]

[im_format_number 1] Partner name: 
<br><dd><input type=text size=45 name=dp_ug.user_groups.group_name [export_form_value group_name]>

<p>[im_format_number 2] Partner short name:
<br><dd><input type=text size=45 name=dp_ug.user_groups.short_name [export_form_value short_name]>

<p>[im_format_number 3] Type:
[im_partner_type_select $db "dp.im_partners.partner_type_id" [value_if_exists partner_type_id]]

<p>[im_format_number 4] Status:
[im_partner_status_select $db "dp.im_partners.partner_status_id" [value_if_exists partner_status_id]]

<p>[im_format_number 5] URL:
<br><dd><input type=text size=45 name=dp.im_partners.url [export_form_value url]>

<p>[im_format_number 6] Notes:
<br><dd><textarea name=dp.im_partners.note rows=6 cols=45 wrap=soft>[philg_quote_double_quotes [value_if_exists note]]</textarea>
 
<p><center><input type=submit value=\"$page_title\"></center>
</form>
"

ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]