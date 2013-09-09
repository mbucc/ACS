ad_page_contract {
    @param group_type the group type
    @param field_name name of the field to add
    @param column_type the type of column
    @param after:optional what is after it
    
    @cvs-id group-type-member-field-add-2.tcl,v 3.2.2.8 2000/09/22 01:36:14 kevin Exp
} {
    group_type:notnull
    field_name:notnull
    column_type:notnull
    after:optional
}
set n_fields_with_this_name [db_string cnt_fields "select count(*)
from (select 1
from user_group_type_member_fields
where group_type = :group_type
and field_name = :field_name
union
select 1
from user_group_member_fields
where group_id in (select group_id from user_groups where group_type = :group_type)
and field_name = :field_name)"]

if { $n_fields_with_this_name > 0 } {
    ad_return_complaint 1 "Either this group type or one of its groups already has a field named \"$field_name\"."
    return
}

if { [exists_and_not_null after] } {
    set sort_key [expr $after + 1]
    set update_sql "update user_group_type_member_fields
set sort_key = sort_key + 1
where group_type = :group_type
and sort_key > :after"
} else {
    set sort_key [db_string max_sort_key "select nvl(max(sort_key)+1,1) from user_group_type_member_fields where group_type = :group_type"]
    set update_sql ""
}

set insert_sql "insert into user_group_type_member_fields (group_type, field_name, field_type, sort_key)
values
( :group_type, :field_name, :column_type, :sort_key)"

db_transaction  {
    if { ![empty_string_p $update_sql] } {
	db_dml update_member_fields $update_sql
    }
    db_dml insert_member_fields $insert_sql
} on_error {
    # an error
    ad_return_error "Database Error" "Error while trying to customize $group_type.
	
Database error message was:	
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>	
"	
    return
}

# database stuff went OK
doc_return  200 text/html "[ad_admin_header "Member Field Added"]

<h2>Member Field Added</h2>

to <a href=\"group-type?[export_url_vars group_type]\">the [db_string get_pretty_name "select pretty_name from user_group_types where group_type = :group_type"] group type</a>

[ad_admin_footer]
"






