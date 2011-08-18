# $Id: view.tcl,v 3.3.2.1 2000/03/17 08:23:06 mbryzek Exp $
# File: /www/intranet/partners/view.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: Lists info about one partner
#

set current_user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables
# group_id

set return_url [ad_partner_url_with_query]

set db [ns_db gethandle]

# Admins and Employees can administer partners
set user_admin_p [im_is_user_site_wide_or_intranet_admin $db $current_user_id]
if { $user_admin_p == 0 } {
    set user_admin_p [im_user_is_employee_p $db $current_user_id]
}

# set user_admin_p [im_can_user_administer_group $db $group_id $current_user_id]



if { $user_admin_p > 0 } {
    # Set up all the admin stuff here in an array
    set admin(basic_info) "  <p><li> <a href=ae.tcl?[export_url_vars group_id return_url]>Edit this information</a>"
    set admin(contact_info) "<p><li><a href=/address-book/record-add.tcl?scope=group&[export_url_vars group_id return_url]>Add a contact</a>"
} else {
    set admin(basic_info) ""
    set admin(contact_info) ""
}
 
set selection [ns_db 1row $db \
	"select g.group_name, g.registration_date, g.modification_date, p.note, p.url, g.short_name, 
                nvl(t.partner_type,'&lt;-- not specified --&gt;') as partner_type,
                nvl(s.partner_status,'&lt;-- not specified --&gt;') as partner_status
	   from user_groups g, im_partners p, im_partner_types t, im_partner_status s
	  where g.group_id=$group_id
	    and g.group_id=p.group_id
	    and p.partner_type_id=t.partner_type_id(+)
	    and p.partner_status_id=s.partner_status_id(+)"]

set_variables_after_query

set page_title $group_name
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] [list index.tcl "Partners"] "One partner"]

set left_column "
<ul> 
  <li> Type: $partner_type
  <li> Status: $partner_status
  <li> Partner short name: $short_name
  <li> Added on [util_AnsiDatetoPrettyDate $registration_date]
" 

if { ![empty_string_p $url] } {
    set url [im_maybe_prepend_http $url]
    append left_column "  <li> URL: <a href=\"$url\">$url</a>\n"
}

if { ![empty_string_p $modification_date] } {
    append left_column "  <li> Last modified on [util_AnsiDatetoPrettyDate $modification_date]\n"
}

if { ![empty_string_p $note] } {
    append left_column "  <li> Notes: <font size=-1>$note</font>\n"
}


append left_column "
$admin(basic_info)
</ul>
"



# Print out the address book
set contact_info ""
set selection [ns_db select $db \
	"select * 
           from address_book 
          where group_id=$group_id
       order by lower(last_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append contact_info "  <p><li>[address_book_record_display $selection "f"]\n"
    if { $user_admin_p > 0 } {
	append contact_info "
<br>
\[<a href=/address-book/record-edit.tcl?scope=group&[export_url_vars group_id address_book_id return_url]>edit</a> | 
<a href=/address-book/record-delete.tcl?scope=group&[export_url_vars group_id address_book_id return_url]>delete</a>\]
"
    }
} 

if { [empty_string_p $contact_info] } {
    set contact_info "  <li> <i>None</i>\n"
}

append left_column "
<b>Contact Information</b>
<ul>
$contact_info
$admin(contact_info)
</ul>

<em>Contact correspondence and strategy reviews:</em>
[ad_general_comments_summary $db $group_id im_partners $group_name]
<ul>
<p><a href=\"/general-comments/comment-add.tcl?group_id=$group_id&scope=group&on_which_table=im_partners&on_what_id=$group_id&item=[ns_urlencode $group_name]&module=intranet&[export_url_vars return_url]\">Add a correspondance</a>
</ul>

"

set page_body "
<table width=100% cellpadding=0 cellspacing=2 border=0>
<tr>
  <td valign=top>
$left_column
  </td>
  <td valign=top>
[im_table_with_title "[ad_parameter SystemName] Employees" "<ul>[im_users_in_group $db $group_id $current_user_id "are working with $group_name" $user_admin_p $return_url [im_employee_group_id]]</ul>"]
  </td>
</tr>
</table>

"

ns_db releasehandle $db
ns_return 200 text/html [ad_partner_return_template]