ad_page_contract {
    Swaps two sort keys for group_type, sort_key and sort_key + 1.
    @param group_type the type of group
    @param sort_key the sort ordering key

    @cvs-id group-type-member-field-swap.tcl,v 3.1.6.4 2000/07/22 06:39:42 ryanlee Exp
} {
    group_type:notnull
    sort_key:notnull,naturalnum
}

set next_sort_key [expr $sort_key + 1]

with_catch errmsg {
    db_dml update_ugtype_member_fields "update user_group_type_member_fields
set sort_key = decode(sort_key, :sort_key, :next_sort_key, :next_sort_key, :sort_key)
where group_type = :group_type
and sort_key in (:sort_key, :next_sort_key)"

    ad_returnredirect "group-type?group_type=[ns_urlencode $group_type]"
} {
    ad_return_error "Database error" "A database error occured while trying
to swap your user group fields. Here's the error:
<pre>
$errmsg
</pre>
"
}












