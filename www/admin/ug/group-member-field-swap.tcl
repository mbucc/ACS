ad_page_contract {
    Swaps two sort keys for group_id, sort_key and sort_key + 1.

    @param group_id The group ID these member fields are for
    @param sort_key The current key of the field whose location is getting swapped

    @cvs-id group-member-field-swap.tcl,v 3.1.6.4 2000/07/21 22:11:49 ryanlee Exp
} {
    group_id:naturalnum,notnull
    sort_key:naturalnum,notnull
}

set next_sort_key [expr $sort_key + 1]

with_catch errmsg {
    db_dml set_new_sort_key "update user_group_member_fields
set sort_key = decode(sort_key, :sort_key, :next_sort_key, :next_sort_key, :sort_key)
where group_id = :group_id
and sort_key in (:sort_key, :next_sort_key)"

    ad_returnredirect "group?group_id=$group_id"
} {
    ad_return_error "Database error" "A database error occured while trying
to swap your user group fields. Here's the error:
<pre>
$errmsg
</pre>
"
}