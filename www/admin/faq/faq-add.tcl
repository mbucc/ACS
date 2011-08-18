
# admin/faq/faq-add.tcl
#
#   A form for creating a new faq (just the name and associated group)
#
#  by dh@arsdigita.com,    Created on Dec 20, 1999
#
# $Id: faq-add.tcl,v 3.0.4.1 2000/03/16 03:16:52 dh Exp $
#-------------------------------------------------

set db [ns_db gethandle]

# get the next faq_id
set next_faq_id [database_to_tcl_string $db "select faq_id_sequence.nextval from dual"]

# make and option list of all the group names
set selection [ns_db select $db "
select group_name, 
       group_id 
from  user_groups
where user_groups.group_type <> 'administration' 
order by group_name "]

set group_option_list "<select name=group_id> \n"
append group_option_list "<option value=\"\">No group \n"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append group_option_list "<option value=$group_id>$group_name \n"
}
append group_option_list "</select>"
ns_db releasehandle $db


# -- serve the page -------------------------------

ns_return 200 text/html "
[ad_admin_header "Create a FAQ"]


<h2>Create a FAQ</h2>

[ad_admin_context_bar [list index "FAQs"] "Create a FAQ"]

<hr>

<form action=faq-add-2.tcl  method=post>
[export_form_vars next_faq_id]
<table>
<tr>
 <td><b>Name</b>:</td>
 <td><input type=text name=faq_name></td>
</tr>

<tr>
 <td><b>Group</b>:</td>
 <td>$group_option_list</td>
</tr>
<tr>
 <td></td>
 <td><input type=submit value=\"Submit\"></td>
</tr>
</table>


[ad_admin_footer]"

