# sort-custom.tcl

ad_page_contract {
    Takes the data generated from ad_table_sort_form function 
    and inserts into the user_custom table.
    On success it does an ad_returnredirect to return_url&$item_group=$item.

    @author davis@arsdigita.com
    @creation-date 2000-01-05
    @cvs-id sort-custom.tcl,v 3.2.2.3 2000/07/24 06:34:44 kevin Exp
} {
    item
    item_group
    return_url
    {delete_the_sort 0}
    col:multiple
    dir:multiple
    {item_original {}}
}


set user_id [ad_verify_and_get_user_id] 
ad_maybe_redirect_for_registration    
set item_type {table_sort}
set value_type {list}

if {$delete_the_sort && ![empty_string_p $item]} {
    util_dbq {item item_type value_type item_group}
    if {[catch {db_dml unused "delete user_custom
          where user_id = $user_id and item = $DBQitem and item_group = $DBQitem_group
            and item_type = $DBQitem_type"} errmsg]} {
        ad_return_complaint 1 "<li>I was unable to delete the sort.  The database said <pre>$errmsg</pre>\n"
        return
    }
    ad_returnredirect "$return_url"
    return
}

if {[empty_string_p $item]} {
    ad_return_complaint 1 "<li>You did not specify a name for this sort"
    return
}

set col_clean {}
set direction(asc) {}
set direction(desc) {*}

# Strip the blank columns...
set i 0 
foreach c $col {
    if {![empty_string_p $c]} {
        lappend col_clean "$c$direction([lindex $dir $i])"
    }
    incr i
}

if {[empty_string_p $col_clean]} {
    ad_return_complaint 1 "<li>You did not specify any columns to sort by"
    return
}

set col_clean [join $col_clean ","]

db_transaction {
    db_dml user_custom_delete {
	delete user_custom
	where user_id = :user_id and item = :item_original and item_group = :item_group
        and item_type = :item_type
    }
    db_dml user_custom_insert {
	insert into user_custom (user_id, item, item_group, item_type, value_type, value)
	values (:user_id, :item, :item_group, :item_type, 'list', empty_clob())
	returning value into :1
    } -clobs [list $col_clean]
} on_error {
    ad_return_complaint 1 "<li>I was unable to insert your table customizations.  The database said <pre>$errmsg</pre>\n"
    return
}

ad_returnredirect "$return_url&$item_group=[ns_urlencode $item]"

