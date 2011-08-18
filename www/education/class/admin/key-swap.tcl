#
# /www/education/class/admin/key-swap.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page swaps the two keys in the edu_role_pretty_role_map
#
# it swaps key with key + 1

ad_page_variables {
    key
    column
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Permissions"]
set class_id [lindex $id_list 1]

set next_key [expr $key + 1]

with_catch errmsg {
    ns_db dml $db "update edu_role_pretty_role_map
    set $column = decode($column, $key, $next_key, $next_key, $key)
    where group_id = $class_id
    and $column in ($key, $next_key)"

    ad_returnredirect "permissions.tcl"
} {
    ad_return_error "Database error" "A database error occured while trying
to swap your user group fields. Here's the error:
<pre>
$errmsg
</pre>
"
}