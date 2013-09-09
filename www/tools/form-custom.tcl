# /www/form-custom.tcl

ad_page_contract {
    Takes the data generated from ad_table_sort_form function 
    and inserts into the user_custom table.
    On success it does an ad_returnredirect to return_url.

    @author davis@arsdigita.com
    @creation-date 2000-01-05
    @cvs-id form-custom.tcl,v 3.2.2.3 2000/07/24 06:44:44 kevin Exp
} {
    item
    item_group 
    return_url 
    {item_original {}}
    {delete_the_set 0}
}


set internals {item item_group return_url item_original delete_the_set}

set user_id [ad_verify_and_get_user_id] 
ad_maybe_redirect_for_registration    
set item_type {slider_custom}
set value_type {keyval}

if {$delete_the_set && ![empty_string_p $item]} {
    if { [catch { db_dml user_custom_delete {
	delete user_custom
	where user_id = :user_id 
	and item = :item 
	and item_group = :item_group
	and item_type = :item_type
    } } errmsg] } {
        ad_return_complaint 1 "<li>I was unable to delete the defaults.  The database said <pre>$errmsg</pre>\n"
        return
    }
    ad_returnredirect "$return_url"
    return
}

           
if {[empty_string_p $item]} {
    ad_return_complaint 1 "<li>You did not specify a name for this default set."
    return
}

# This is some bad voodoo, ought to rewrite with an array of values

set form [ns_getform]
for {set i 0} { $i < [ns_set size $form]} {incr i} {
    if {[lsearch $internals [ns_set key $form $i]] < 0} { 
        lappend data [list [ns_set key $form $i] [ns_set value $form $i]]
    }
}

if {[empty_string_p $data]} {
    ad_return_complaint 1 "<li>You did not specify any default data."
    return
}

db_transaction {
    db_dml user_custom_delete {
	delete user_custom
	where user_id = :user_id 
	and item = :item_original 
	and item_group = :item_group
        and item_type = :item_type
    }
    db_dml user_custom_insert {
	insert into user_custom (user_id, item, item_group, item_type, value_type, value)
	values (:user_id, :item, :item_group, :item_type, 'list', empty_clob())
	returning value into :1
    } -clobs [list $data]
} on_error {
    ad_return_complaint 1 "
    <li>Unable to insert your defaults. The database said <pre>$errmsg</pre>\n"
    return
}

ad_returnredirect "$return_url"

