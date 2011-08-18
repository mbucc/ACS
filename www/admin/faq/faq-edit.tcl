
# admin/faq/faq-edit.tcl
#
#   A form for editing a faq (just the name and associated group)
#
#  by dh@arsdigita.com , Created on Dec 20, 1999
#
# $Id: faq-edit.tcl,v 3.0.4.1 2000/03/16 03:18:53 dh Exp $
#-------------------------------------------------

ad_page_variables {faq_id}

set db [ns_db gethandle]

# get the faq_name, group_id, scope
set selection [ns_db 1row $db "
select faq_name, group_id as current_group_id, scope
from faqs
where faq_id = $faq_id"]
set_variables_after_query

# make and option list of all the group names
set selection [ns_db select $db "
select group_name, 
       group_id 
from  user_groups
where user_groups.group_type <> 'administration' 
order by group_name "]

set group_option_list "<select name=group_id> \n"
append group_option_list "<option value=\"\" [expr {""==$current_group_id?"selected":""}]>No group \n"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append group_option_list "<option value=$group_id [expr {$group_id==$current_group_id?"selected":""}]>$group_name \n"
}
append group_option_list "</select>"
ns_db releasehandle $db


# -- serve the page -------------------------------

ns_return 200 text/html "
[ad_admin_header "Edit a FAQ"]

<h2>Edit a FAQ</h2>

[ad_admin_context_bar [list index "FAQs"] [list "one?faq_id=$faq_id" "$faq_name"] "Edit FAQ"]

<hr>

<form action=faq-edit-2.tcl  method=post>
[export_form_vars faq_id]
<table>
<tr>
 <td><b>Name</b>:</td>
 <td><input type=text name=faq_name value=\"[philg_quote_double_quotes $faq_name]\"></td>
</tr>

<tr>
 <td><b>Group</b>:</td>
 <td>$group_option_list</td>
</tr>
<tr>
<td></td>
<td><input type=submit value=\"Submit\"></td>
</table>

[ad_admin_footer]"

