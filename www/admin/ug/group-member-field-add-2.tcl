# $Id: group-member-field-add-2.tcl,v 3.0 2000/02/06 03:28:48 ron Exp $
set_the_usual_form_variables

# group_id, field_name, column_type, after (optional)

set db [ns_db gethandle]

set n_fields_with_this_name [database_to_tcl_string $db "select count(*)
from all_member_fields_for_group
where group_id = $group_id
and field_name = '$QQfield_name'"]

if { $n_fields_with_this_name > 0 } {
    ad_return_complaint 1 "Either this group or its group type already has a field named \"$field_name\"."
    return
}

if { [exists_and_not_null after] } {
    set sort_key [expr $after + 1]
    set update_sql "update user_group_member_fields
set sort_key = sort_key + 1
where group_id = $group_id
and sort_key > $after"
} else {
    set sort_key 1
    set update_sql ""
}

set insert_sql "insert into user_group_member_fields (group_id, field_name, field_type, sort_key)
values
( $group_id, '$QQfield_name', '$QQcolumn_type', $sort_key)"

set group_name [database_to_tcl_string $db "select group_name from user_groups where group_id = $group_id"]

with_transaction $db {
    if { ![empty_string_p $update_sql] } {
	ns_db dml $db $update_sql
    }
    ns_db dml $db $insert_sql
} {
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

# database stuff went OK
ns_return 200 text/html "[ad_admin_header "Member Field Added"]

<h2>Member Field Added</h2>

to <a href=\"group.tcl?[export_url_vars group_id]\">the $group_name group</a>

[ad_admin_footer]
"
