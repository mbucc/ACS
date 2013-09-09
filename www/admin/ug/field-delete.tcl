ad_page_contract {
    @param group_type the group type
    @param group_type_pretty_name plain english name for the group type
    @param column_name database column name
    @param pretty_name the plain english name for the column

    @cvs-id field-delete.tcl,v 3.1.6.6 2000/09/22 01:36:12 kevin Exp
} {
    group_type:notnull
    group_type_pretty_name:notnull
    column_name:notnull
    pretty_name:notnull
}

set group_count [db_string get_count_from_ug "select count(*) from user_groups where group_type = :group_type"]

doc_return  200 text/html "[ad_admin_header "Delete Field From User Group Type"]

<h2>Delete Column $pretty_name ($column_name)</h2>

from the <a href=\"group-type?[export_url_vars group_type]\">$group_type_pretty_name</a> group type

<hr> 

<form action=\"field-delete-2\" method=POST>
[export_form_vars group_type column_name]

Do you really want to remove this field from this group type, and all $group_count groups of this type?
<p>
You may not be able to undo this action.
<center>
<input type=submit value=\"Yes, Remove This Field\">
</center>

[ad_admin_footer]
"
