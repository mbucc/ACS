ad_page_contract {
    @param group_type the type of group
    @param field_name the name of the field to delete
    @param group_type_pretty_name the human recogniseable name

    @cvs-id group-type-member-field-delete.tcl,v 3.1.6.5 2000/09/22 01:36:14 kevin Exp
} {
    group_type:notnull
    field_name:notnull
    group_type_pretty_name:notnull
}


set page_html  "[ad_admin_header "Delete Field From User Group Type"]

<h2>Delete Column $field_name</h2>

from the <a href=\"group-type?[export_url_vars group_type]\">$group_type_pretty_name</a> group type

<hr> 

<form action=\"group-type-member-field-delete-2\" method=POST>
[export_form_vars group_type field_name]

Do you really want to remove this field from this group type, and all 
[db_string get_count_from_ug "select count(*) from user_groups where group_type = :group_type"] groups of this type?
<p>
You may not be able to undo this action.
<center>
<input type=submit value=\"Yes, Remove This Field\">
</center>

[ad_admin_footer]
"


doc_return  200 text/html $page_html

