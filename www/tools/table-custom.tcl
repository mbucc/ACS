#/www/tools/table-custom.tcl

ad_page_contract {

    Takes the data generated from ad_table_form function 
    and inserts into the user_custom table
    on success, it does an ad_returnredirect to return_url&$item_group=$item

    @author davis@arsdigita.com 
    @creation-date 01/05/2000
    @param item
    @param item_group
    @param return_url
    @param delete_the_view
    @param item_original
    @param col
    @cvs-id table-custom.tcl,v 3.1.6.4 2000/09/16 16:48:36 kevin Exp
} {
    {item:notnull}
    {item_group:notnull}
    {return_url:notnull}
    {delete_the_view:optional 0}
    {item_original ""}
    {col:multiple,optional}
}

set user_id [ad_verify_and_get_user_id] 
ad_maybe_redirect_for_registration    

set item_type {table_view}
set value_type {list}

if {$delete_the_view && ![empty_string_p $item]} {
    if {[catch {db_dml delete_user_custom "delete user_custom
          where user_id = :user_id and item = :item and item_group = :item_group
            and item_type = :item_type"} errmsg]} {
        ad_return_complaint 1 "<li>I was unable to delete the view.  The database said <pre>$errmsg</pre>\n"
        
	db_release_unused_handles
	return
    }
    
    db_release_unused_handles
    ad_returnredirect "$return_url"
}

        
if {[empty_string_p $item]} {
    ad_return_complaint 1 "<li>You did not specify a name for this table view"

    db_release_unused_handles
    return
}

set col_clean [list]

# Strip the blank columns...
foreach c $col {
    if {![empty_string_p $c]} {
        lappend col_clean $c
    }
}

if {[empty_string_p $col_clean]} {
    ad_return_complaint 1 "<li>You did not specify any columns to display"
    return
}

db_transaction {
    db_dml user_custom_delete {
	delete user_custom
	where user_id    = :user_id 
        and   item       = :item_original 
        and   item_group = :item_group
        and   item_type  = :item_type
    }
    db_dml user_custom_insert {
	insert into user_custom (user_id, item, item_group, item_type, value_type, value)
	values (:user_id, :item, :item_group, :item_type, 'list', empty_clob())
	returning value into :1
    } -clobs [list $col_clean]
} on_error {
    ad_return_complaint 1 "
    <li>Unable to insert your table customizations.  The database said <pre>$errmsg</pre>\n"
    return
}

db_release_unused_handles

ad_returnredirect "$return_url&$item_group=[ns_urlencode $item]"

