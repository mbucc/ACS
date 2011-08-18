# /admin/pull-down-menus/item-add-2.tcl
#
# by aure@caltech.edu
#
# 2000-02-18
#
# $Id: item-add-2.tcl,v 1.1.2.2 2000/04/28 15:09:18 carsten Exp $


ad_page_variables {
    {menu_id}
    {parent_key ""}
    {label "" qq}
    {url "" qq}
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

set db [ns_db gethandle]

# Get the sort_key for the parent of this page

if [empty_string_p $parent_key] {
    # we're adding a top-level item for the menu, so get the
    # current maximum sort key

    set max_sort_key [database_to_tcl_string $db "
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

    set max_sort_key [database_to_tcl_string $db "
    select max(sort_key)
    from   pdm_menu_items
    where  sort_key like '${parent_key}__'"]

    if [empty_string_p $max_sort_key] {
	# parent has no children - this is the first one
	set next_sort_key "${parent_key}00"
    } else {
	# new key will be the same length
	set key_length [string length $max_sort_key]

	# make sure adding a new child won't overflow the keys
	set max_sort_key [string trimleft $max_sort_key 0]
	if {[expr $max_sort_key % 100]==99} {
	    ad_return_complaint 1 "
	    <li>You cannot have more than 100 subitems in any item."
	    return
	} else {
	    set next_sort_key [format "%0${key_length}d" [expr $max_sort_key+1]]
	}
    }
}

# Insert this item into the database

set item_id [database_to_tcl_string $db \
	"select pdm_item_id_sequence.nextval from dual"]

ns_db dml $db "
insert into pdm_menu_items
 ( item_id,
   menu_id,
   label,
   sort_key,
   url)
values
 ( pdm_item_id_sequence.nextval,
   $menu_id,
  '$QQlabel',
  '$next_sort_key',
  '$QQurl'
)"


ad_returnredirect "items?menu_id=$menu_id"



