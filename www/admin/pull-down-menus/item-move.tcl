# /admin/pull-down-menus/item-move.tcl
#
# by aure@caltech.edu
#
# 2000-02-18
#
# $Id: item-move.tcl,v 1.1.2.1 2000/03/16 05:33:08 aure Exp $

ad_page_variables {item_id}

set page_title "Move Item"

set db [ns_db gethandle]

# get the current item and pdm information
set selection [ns_db 1row $db "
    select item_id  as root_id, 
           sort_key as root_key,
           pdm_menus.menu_id,
           pdm_menus.menu_key
    from   pdm_menu_items, pdm_menus 
    where  item_id = $item_id
    and    pdm_menu_items.menu_id=pdm_menus.menu_id"]
set_variables_after_query

set selection [ns_db select $db "
select item_id,
       label,
       sort_key
from   pdm_menu_items
where  menu_id = $menu_id
order by sort_key"]

set item_depth 0
set item_list ""

while {[ns_db getrow $db $selection]} {

    set_variables_after_query
    
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

ns_db releasehandle $db   

# -----------------------------------------------------------------------------

ns_return 200 text/html "
[ad_header_with_extra_stuff "$page_title" [ad_pdm $menu_key 5 5] [ad_pdm_spacer $menu_key]]

<h2>$page_title</h2>

[ad_admin_context_bar [list "" "Pull-Down Menus"] [list "pdm-edit?menu_id=$menu_id" $menu_key] $page_title]

<hr>

<p>Click on the item that you would like to move \"$label\" 
under, or on \"Top\" to make it a top level item.

<blockquote>
<a href=\"item-move-2?menu_id=$menu_id&item_id=$root_id\">Top</a>
<p>
$item_list
<p>
</blockquote>
<p>

[ad_admin_footer]"




