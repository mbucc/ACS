# $Id: group-type-member-field-delete-2.tcl,v 3.0 2000/02/06 03:29:14 ron Exp $
set_the_usual_form_variables

# group_type, field_name

set db [ns_db gethandle]

set table_name [ad_user_group_helper_table_name $group_type]

with_transaction $db {

    set ugmfm_count [database_to_tcl_string $db "select count(*) 
from user_group_member_field_map 
where field_name = '$QQfield_name'"]

    set ugtmf_count [database_to_tcl_string $db "select count(*) 
from user_group_type_member_fields 
where group_type = '$QQgroup_type'
and field_name = '$QQfield_name'"]

    ns_db dml $db "delete from user_group_member_field_map 
where field_name = '$QQfield_name'"
    ns_db dml $db "delete from user_group_type_member_fields
where group_type = '$QQgroup_type'
and field_name = '$QQfield_name'"

} {
    ad_return_error "Deletion Failed" "We were unable to drop the column $field_name from user group type $group_type due to a database error:
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

The following actions were performed:

<ul>
"
if {$ugtmf_count == 1} {
    ns_write "
<li>$ugtmf_count row removed from the table user_group_type_member_fields."
} else {
    ns_write "
<li>$ugtmf_count rows removed from the table user_group_type_member_fields."
}
if {$ugmfm_count == 1} {
    ns_write "
<li>$ugmfm_count row removed from the table user_group_member_field_map."
} else {
    ns_write "
<li>$ugmfm_count rows removed from the table user_group_member_field_map."
}
ns_write "

</ul>

[ad_admin_footer]
"