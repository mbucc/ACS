# /admin/pull-down-menus/item-move-2.tcl
#
# by aure@caltech.edu
#
# 2000-02-18
#
# $Id: item-move-2.tcl,v 1.1.2.2 2000/04/28 15:09:18 carsten Exp $

ad_page_variables {
    {item_id}
    {menu_id}
    {parent_id ""}
    {move ""}
}


# ---------------------------------------------------------------

# There are two things we could be doing on this page.  We might be moving
# a item to a new parent or we might be moving it up or down.  We split 
# these into two procs.

proc new_parent {item_id menu_id parent_id} {

    set db [ns_db gethandle]

    if { [empty_string_p $parent_id] } {
	set parent_key ""
    } else {
	set parent_key [database_to_tcl_string $db "
	select sort_key from pdm_menu_items where item_id = $parent_id"]
    }

    set num [database_to_tcl_string_or_null $db "
      select max(sort_key) from pdm_menu_items 
      where  sort_key like '${parent_key}__'"]

    # find the proper sort_key for the next subitem to this parent

    set len [string length $num]

    # avoid TCL's octal predilections
    set temp [string trimleft $num 0]
    if {[empty_string_p $temp]} {
	set temp 0
    }

    if { [empty_string_p $num] } {
	# first subitem
	set num "${parent_key}00"
    } elseif { [expr ${temp}%100] == 99 } {
	ad_return_complaint 1 "<li>You cannot have more than 100 subitems in any item.\n"
	return
    } else {
	incr temp
	# don't forget to pad with any zeros we chopped off
	set num [format "%0${len}d" $temp]
    }

    # now move the item and all its children

    set sort_key [database_to_tcl_string $db "
        select sort_key 
        from pdm_menu_items
        where item_id = $item_id"]
    set len [string length $sort_key]
    if { [catch { 
	ns_db dml $db "
	update pdm_menu_items
	set sort_key = '$num' || substr(sort_key, $len + 1)
	where sort_key like '$sort_key%'"
    } error_msg] } {
	
	ns_db releasehandle $db
	ad_return_complaint 1 "<li>A database error occurred.  Make sure you
	start from the main administation page.\n$error_msg\n"
	
	return

    } else {

	ns_db releasehandle $db
	ad_returnredirect "items?menu_id=$menu_id"
	return
 
    }   
}



proc move_item {item_id menu_id move} {

    set db [ns_db gethandle]
    ns_db dml $db "begin transaction"

    set sort_key [database_to_tcl_string $db "
        select sort_key 
        from pdm_menu_items
        where item_id = $item_id"]

    regexp {(.*)[0-9][0-9]} $sort_key match prefix

    # find the right item to swap with

    if { $move == "up" } {
	set temp [database_to_tcl_string_or_null $db "
	select max(sort_key)
	from   pdm_menu_items
	where  sort_key like '${prefix}__'
	and    sort_key < '$sort_key'"]
    } elseif { $move == "down" } {
	set temp [database_to_tcl_string_or_null $db "
	select min(sort_key)
	from   pdm_menu_items
	where  sort_key like '${prefix}__'
	and    sort_key > '$sort_key'"]
    } else {
	ad_returncomplaint 1 "<li>This page was not called with the correct
	form variables.\n"
	ns_db dml $db "end transaction"
	ns_db releasehandle $db
	return
    }

    # juggle the sort_keys to achieve the swap

    if { ![empty_string_p $temp] } {
	set len [string length $sort_key]
	# length(sort_key) = length(temp)

	ns_db dml $db "update pdm_menu_items
	set   sort_key = '-1' || substr(sort_key, $len + 1)
	where sort_key like '$sort_key%'"

	ns_db dml $db "update pdm_menu_items
	set   sort_key = '$sort_key' || substr(sort_key, $len + 1)
	where sort_key like '$temp%'"

	ns_db dml $db "update pdm_menu_items
	set   sort_key = '$temp' || substr(sort_key, 3)
	where sort_key like '-1%'"

	set new_id [database_to_tcl_string $db "
	select item_id 
	from   pdm_menu_items 
        where  sort_key  = '$temp'"]
    } else {
	set new_id $item_id
    }

    ns_db dml $db "end transaction"
    ns_db releasehandle $db
    ad_returnredirect "items?menu_id=$menu_id"
    return
    
}


# -------------------------------------------------------------------

# main body

if ![empty_string_p $move ] {
    move_item $item_id $menu_id $move
} else {
    new_parent $item_id $menu_id $parent_id
}

