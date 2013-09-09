# /www/admin/pull-down-menus/item-move-2.tcl
ad_page_contract {

  There are two things we could be doing on this page.  We might be moving
  a item to a new parent or we might be moving it up or down.

  @param item_id Item we're about to move.
  @param menu_id Menu that item belongs to.
  @param move Direction of move if moving up or down from items.tcl.
  @param parent_id Parent item id if we're assigning item a new parent.

  @author aure@caltech.edu
  @creation-date 2000-02-18
  @cvs-id item-move-2.tcl,v 1.4.2.6 2000/08/11 22:34:46 randyb Exp

} {

    item_id:integer,notnull
    menu_id:integer,notnull
    {parent_id:integer ""}
    {move ""}

}

# ---------------------------------------------------------------

# There are two things we could be doing on this page.  We might be moving
# a item to a new parent or we might be moving it up or down.  We split 
# these into two procs.

proc new_parent {item_id menu_id parent_id} {

    

    if { [empty_string_p $parent_id] } {
	set parent_key ""
    } else {
	set parent_key [db_string get_parent_sort_key "
	  select sort_key from pdm_menu_items
	  where item_id = :parent_id" ]
    }

    set parent_key_item  "${parent_key}__"

    set num [db_string get_max_sort_key_for_children_of_new_parent "
      select max(sort_key) from pdm_menu_items 
      where  sort_key like :parent_key_item" -default "" ]

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
	db_release_unused_handles
	ad_return_complaint 1 "<li>You cannot have more than 100 subitems in any item.\n"
	return
    } else {
	incr temp
	# don't forget to pad with any zeros we chopped off
	set num [format "%0${len}d" $temp]
    }

    # now move the item and all its children

    set sort_key [db_string get_item_sort_key "
        select sort_key 
        from pdm_menu_items
        where item_id = :item_id" ]

    set sort_key_item  "${sort_key}%"

    set len [string length $sort_key]
    if { [catch { 
	db_dml update_sort_keys_for_item_and_all_its_children "
	update pdm_menu_items
	set sort_key = :num || substr(sort_key, :len + 1)
	where sort_key like :sort_key_item" 
    } error_msg] } {
	
	db_release_unused_handles
	ad_return_complaint 1 "<li>A database error occurred.  Make sure you
	start from the main administation page.\n$error_msg\n"
	
	return

    } else {

	db_release_unused_handles
	ad_returnredirect "items?menu_id=$menu_id"
	return
 
    }   
}

proc move_item {item_id menu_id move} {

    
    db_transaction {

    set sort_key [db_string get_item_sort_key_2 "
        select sort_key 
        from pdm_menu_items
        where item_id = :item_id" ]

    regexp {(.*)[0-9][0-9]} $sort_key match prefix

    set prefix_item "${prefix}__"

    # find the right item to swap with

    if { $move == "up" } {
	set temp [db_string get_max_sort_key_2 "
	select max(sort_key)
	from   pdm_menu_items
	where  sort_key like :prefix_item
	and    sort_key < :sort_key" -default "" ]
    } elseif { $move == "down" } {
	set temp [db_string get_min_sort_key "
	select min(sort_key)
	from   pdm_menu_items
	where  sort_key like :prefix_item
	and    sort_key > :sort_key" -default "" ]
    } else {
	ad_returncomplaint 1 "<li>This page was not called with the correct
	form variables.\n"
	db_release_unused_handles
	return
    }

    # juggle the sort_keys to achieve the swap

    if { ![empty_string_p $temp] } {
	set len [string length $sort_key]
	# length(sort_key) = length(temp)

	set sort_key_item "${sort_key}%"

	db_dml swap_sort_keys_1 "update pdm_menu_items
	set   sort_key = '-1' || substr(sort_key, :len + 1)
	where sort_key like :sort_key_item" 

	set temp_item "${temp}%"

	db_dml swap_sort_keys_2 "update pdm_menu_items
	set   sort_key = :sort_key || substr(sort_key, :len + 1)
	where sort_key like :temp_item" 

	db_dml swap_sort_keys_3 "update pdm_menu_items
	set   sort_key = :temp || substr(sort_key, 3)
	where sort_key like '-1%'" 

	set new_id [db_string get_new_id "
	select item_id 
	from   pdm_menu_items 
        where  sort_key  = :temp" ]
    } else {
	set new_id $item_id
    }

    }

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

# figure out whether this menu is the default
set default_menu_p [db_string menu_is_default "select default_p from pdm_menus where menu_id = :menu_id"]

if {$default_menu_p == "t"} {
    # flush the current default menu from the memory cache - it will get memoized again when it's next called
    util_memoize_flush "ad_pdm_helper \"\" \"\" \"\" 1"
}

db_release_unused_handles
