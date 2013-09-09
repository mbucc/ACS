# /www//admin/pull-down-menus/item-move.tcl
ad_page_contract {

  Rearanges menu item within its menu group.

  @param item_id Item we're about to move

  @author aure@caltech.edu
  @creation-date 2000-02-18
  @cvs-id item-move.tcl,v 1.3.2.5 2000/09/22 01:35:55 kevin Exp

} {

  item_id:integer,notnull

}

set page_title "Move Item"

# get the current item and pdm information
db_1row one_item "
    select item_id  as root_id, 
           sort_key as root_key,
	   label as item_label,
           pdm_menus.menu_id,
           pdm_menus.menu_key
    from   pdm_menu_items, pdm_menus 
    where  item_id = :item_id
    and    pdm_menu_items.menu_id=pdm_menus.menu_id" 

set item_depth 0
set item_list ""

db_foreach all_menu_items "
select item_id,
       label,
       sort_key
from   pdm_menu_items
where  menu_id = :menu_id
order by sort_key" {

    # Note that we can only descend by a unit amount, but we can
    # acscend by an arbitrary amount.

    if { [string length $sort_key] > $item_depth } {
	append item_list "<ul>\n"
	incr item_depth 2
    } elseif {[string length $sort_key] < $item_depth} {
	while { [string length $sort_key] < $item_depth } {
	    append item_list "</ul>\n"
	    incr item_depth -2
	}
    }

    # A item can only be moved to higher parts of the tree, so
    # check so see if the current item is a child of the one we're
    # moving 

    if {[regexp "^$root_key" $sort_key match] } {
	append item_list "<li>$label\n"
    } else {
	append item_list "
	<li>
	<a href=item-move-2?item_id=$root_id&menu_id=$menu_id&parent_id=$item_id>$label</a>\n"
    }
}

# Make sure we get back to zero depth

while {$item_depth > 0} {
    append item_list "</ul>\n"
    incr   item_depth -2
}

db_release_unused_handles   

# -----------------------------------------------------------------------------

doc_return  200 text/html "
[ad_header_with_extra_stuff "$page_title" [ad_pdm $menu_key 5 5] [ad_pdm_spacer $menu_key]]

<h2>$page_title</h2>

[ad_admin_context_bar [list "" "Pull-Down Menus"] [list "pdm-edit?menu_id=$menu_id" $menu_key] $page_title]

<hr>

<p>Click on the item that you would like to move \"$item_label\" 
under, or on \"Top\" to make it a top level item.

<blockquote>
<a href=\"item-move-2?menu_id=$menu_id&item_id=$root_id\">Top</a>
<p>
$item_list
<p>
</blockquote>
<p>

[ad_admin_footer]"

