# $Id: field-delete-2.tcl,v 3.0 2000/02/06 03:28:37 ron Exp $
set_the_usual_form_variables

# group_type, column_name

set db [ns_db gethandle]

set table_name [ad_user_group_helper_table_name $group_type]

with_transaction $db {
    ns_db dml $db "delete from user_group_type_fields
where group_type = '$QQgroup_type'
and column_name = '$QQcolumn_name'"
    ns_db dml $db "alter table $table_name drop column $column_name"
} {
    ad_return_error "Deletion Failed" "We were unable to drop the column $column_name from user group type $group_type due to a database error:
<pre>
$errmsg
</pre>
"
    return
}

ns_return 200 text/html "[ad_admin_header "Field Removed"]

<h2>Field Removed</h2>

from <a href=\"group-type.tcl?[export_url_vars group_type]\">the $group_type group type</a>

<hr>

The following action has been taken:

<ul>

<li>the column \"$column_name\" was removed from the table
$table_name.
<li>a row was removed from the table user_group_type_fields.
</ul>

[ad_admin_footer]
"