ad_page_contract {
    @param group_type the group type
    @param field_name the name of the field to delete
    
    @cvs-id group-type-member-field-delete-2.tcl,v 3.1.6.5 2000/09/22 01:36:14 kevin Exp
} {
    group_type:notnull
    field_name:notnull
}

set table_name [ad_user_group_helper_table_name $group_type]

db_transaction {

    set ugmfm_count [db_string get_ugmfm_cnt "select count(*) 
from user_group_member_field_map 
where field_name = :field_name"]

    set ugtmf_count [db_string get_umtmf_cnt "select count(*) 
from user_group_type_member_fields 
where group_type = :group_type
and field_name = :field_name"]

    db_dml ugmtm_delete "delete from user_group_member_field_map 
where field_name = :field_name"
    db_dml ugtmf_delete "delete from user_group_type_member_fields
where group_type = :group_type
and field_name = :field_name"

} on_error {
    ad_return_error "Deletion Failed" "We were unable to drop the column $field_name from user group type $group_type due to a database error:
<pre>
$errmsg
</pre>
"
    return
}

set page_content "[ad_admin_header "Field Removed"]

<h2>Field Removed</h2>

from <a href=\"group-type?[export_url_vars group_type]\">the $group_type group type</a>

<hr>

The following actions were performed:

<ul>
"
if {$ugtmf_count == 1} {
    append page_content "
<li>$ugtmf_count row removed from the table user_group_type_member_fields."
} else {
    append page_content "
<li>$ugtmf_count rows removed from the table user_group_type_member_fields."
}
if {$ugmfm_count == 1} {
    append page_content "
<li>$ugmfm_count row removed from the table user_group_member_field_map."
} else {
    append page_content "
<li>$ugmfm_count rows removed from the table user_group_member_field_map."
}
append page_content "

</ul>

[ad_admin_footer]
"


doc_return  200 text/html $page_content

