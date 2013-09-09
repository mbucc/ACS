# admin/faq/faq-edit.tcl
#

ad_page_contract {
    A form for editing a faq (just the name and associated group)

    @author dh@arsdigita.com
    @creation-date Dec 20, 1999
    @cvs-id faq-edit.tcl,v 3.3.2.7 2000/09/22 01:35:08 kevin Exp
} {
faq_id:integer,notnull
}


# get the faq_name, group_id, scope
db_1row faq_name_get "
select faq_name, group_id as current_group_id, scope
from faqs
where faq_id = :faq_id"


# make and option list of all the group names
set sql "
select group_name, 
       group_id 
from  user_groups
where user_groups.group_type <> 'administration' 
order by group_name "

set group_option_list "<select name=group_id> \n"
append group_option_list "<option value=\"\" [expr {""==$current_group_id?"selected":""}]>No group \n"


db_foreach faq_group_get $sql {
    append group_option_list "<option value=$group_id [expr {$group_id==$current_group_id?"selected":""}]>$group_name \n"
}
append group_option_list "</select>"
db_release_unused_handles


set page_content "
[ad_admin_header "Edit a FAQ"]

<h2>Edit a FAQ</h2>

[ad_admin_context_bar [list index "FAQs"] [list "one?faq_id=$faq_id" "$faq_name"] "Edit FAQ"]

<hr>

<form action=faq-edit-2 method=post>
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



doc_return  200 text/html $page_content
