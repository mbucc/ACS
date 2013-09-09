ad_page_contract {
    @param group_id the ID of the group
    @param field_name the name of the field
    @param column_type the type of the column
    @param after:optional what to do afterwards
    
    @cvs-id group-member-field-add-2.tcl,v 3.1.6.7 2000/09/22 01:36:13 kevin Exp

} {
    group_id:notnull,naturalnum
    field_name:notnull
    column_type:notnull
    after:optional
}



set n_fields_with_this_name [db_string group_field_count "select count(*)
from all_member_fields_for_group
where group_id = :group_id
and field_name = :field_name"]

if { $n_fields_with_this_name > 0 } {
    ad_return_complaint 1 "Either this group or its group type already has a field named \"$field_name\"."
    return
}

if { [exists_and_not_null after] } {
    set sort_key [expr $after + 1]
    set update_sql "update user_group_member_fields
set sort_key = sort_key + 1
where group_id = :group_id
and sort_key > :after"
} else {
    set sort_key 1
    set update_sql ""
}

set insert_sql "insert into user_group_member_fields (group_id, field_name, field_type, sort_key)
values
( :group_id, :field_name, :column_type, :sort_key)"

set group_name [db_string group_get_name "select group_name from user_groups where group_id = :group_id"]

db_transaction {
    if { ![empty_string_p $update_sql] } {
	db_dml group_field_update $update_sql
    }
    db_dml group_field_insert $insert_sql
} on_error {
    # an error
    ad_return_error "Database Error" "Error while trying to customize group $group_name.
	
Database error message was:	
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    return
}

ad_returnredirect "group?[export_url_vars group_id]"
return

# what's the point of showing this?
#
#  # database stuff went OK
#  doc_return  200 text/html "[ad_admin_header "Member Field Added"]

#  <h2>Member Field Added</h2>

#  to <a href=\"group?[export_url_vars group_id]\">the $group_name group</a>

#  [ad_admin_footer]
#  "



