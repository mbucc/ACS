# /www//admin/pull-down-menus/item-add-2.tcl
ad_page_contract {

  Add item to the specified menu group.

  @param menu_id Which menu item will be added to.
  @param parent_key Determine postion of item within menu group.
  @param label Label for item.
  @param url URL this menu item is pointing to.

  @author aure@caltech.edu
  @creation-date 2000-02-18
  @cvs-id item-add-2.tcl,v 1.4.2.5 2000/08/11 22:35:06 randyb Exp

} {

    menu_id:integer,notnull
    label:notnull
    {parent_key ""}
    {url ""}

}


# -----------------------------------------------------------------------------
# Error Checking

set exception_text ""
set exception_count 0

if [empty_string_p $label] {
    incr exception_count
    append exception_text "<li>You must provide an item label"
}

if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# -----------------------------------------------------------------------------



# Get the sort_key for the parent of this page

if [empty_string_p $parent_key] {
    # we're adding a top-level item for the menu, so get the
    # current maximum sort key

    set max_sort_key [db_string get_max_sort_key "
    select max(sort_key)
    from   pdm_menu_items
    where  length(sort_key) = 2"]

    if [empty_string_p $max_sort_key] {
	set next_sort_key "00"
    } else {
	set key_length    [string length $max_sort_key]
	set next_sort_key [format "%0${key_length}d" \
		[expr [string trimleft $max_sort_key 0]+1]]
    }
} else {
    # we're adding a subitem, so grab the maximum sort key among
    # all the children for this parent

    set parent_key_item "${parent_key}__"

    set max_sort_key [db_string get_max_sortkey_of_children "
    select max(sort_key)
    from   pdm_menu_items
    where  sort_key like :parent_key_item" ]

    if [empty_string_p $max_sort_key] {
	# parent has no children - this is the first one
	set next_sort_key "${parent_key}00"
    } else {
	# new key will be the same length
	set key_length [string length $max_sort_key]

	# make sure adding a new child won't overflow the keys
	set max_sort_key [string trimleft $max_sort_key 0]
	if {[expr $max_sort_key % 100]==99} {
	    db_release_unused_handles
	    ad_return_complaint 1 "
	    <li>You cannot have more than 100 subitems in any item."
	    return
	} else {
	    set next_sort_key [format "%0${key_length}d" [expr $max_sort_key+1]]
	}
    }
}

# Insert this item into the database

db_dml insert_menu_item "
insert into pdm_menu_items
 ( item_id,
   menu_id,
   label,
   sort_key,
   url)
values
 ( pdm_item_id_sequence.nextval,
   :menu_id,
   :label,
   :next_sort_key,
   :url
)" 

# figure out whether this menu is the default
set default_menu_p [db_string menu_is_default "select default_p from pdm_menus where menu_id = :menu_id"]

if {$default_menu_p == "t"} {
    # flush the current default menu from the memory cache - it will get memoized again when it's next called
    util_memoize_flush "ad_pdm_helper \"\" \"\" \"\" 1"
}

db_release_unused_handles
ad_returnredirect "items?menu_id=$menu_id"

