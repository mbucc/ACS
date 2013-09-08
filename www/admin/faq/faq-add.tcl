# admin/faq/faq-add.tcl
#

ad_page_contract {
    A form for creating a new faq (just the name and associated group)

    @author dh@arsdigita.com
    @creation-date Dec 20, 1999
    @cvs-id faq-add.tcl,v 3.3.2.8 2001/01/10 18:37:45 khy Exp
} {
}


# get the next faq_id
set faq_id [db_string faq_id_get "select faq_id_sequence.nextval from dual"]

# make and option list of all the group names
set sql "
select group_name, 
       group_id 
from  user_groups
where user_groups.group_type <> 'administration' 
order by group_name"

set group_option_list "<select name=group_id> \n"
append group_option_list "<option value=\"\">No group \n"

db_foreach faq_group_get $sql {
    append group_option_list "<option value=$group_id>$group_name \n"
}
append group_option_list "</select>"
db_release_unused_handles


set page_content "
[ad_admin_header "Create a FAQ"]

<h2>Create a FAQ</h2>

[ad_admin_context_bar [list index "FAQs"] "Create a FAQ"]

<hr>

<form action=faq-add-2 method=post>
[export_form_vars -sign faq_id]
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



doc_return  200 text/html $page_content