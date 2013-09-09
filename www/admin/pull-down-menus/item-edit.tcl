# /www/admin/pull-down-menus/item-edit.tcl
ad_page_contract {
  
  Allows the user the edit the parameters for a item.

  @param item_id which menu item we're editing

  @author aure@arsdigita.com
  @creation-date 2000-02-18
  @cvs-id item-edit.tcl,v 1.4.2.6 2000/09/22 01:35:54 kevin Exp

} {

  item_id:integer

}



set page_title "Edit Item"

# Get the data for this item

db_1row item {
  select label,
	 url,
	 menu_id,
	 sort_key as root_key
  from   pdm_menu_items
  where  item_id = :item_id
}


# Get this item's parent

set parent_key [string range $root_key 0 [expr [string length $root_key]-3]]

set parent_exists_p [db_0or1row parent_item {
  select label as parent_title,
	 item_id    as parent_id
  from   pdm_menu_items
  where  sort_key  = :parent_key
  and    menu_id = :menu_id
} ]

if { !$parent_exists_p } {
    set item_parent "Top Level"
} else {
    set item_parent "<a href=item-edit?menu_id=$menu_id&item_id=$parent_id>
    $parent_title</a>"
}

# Get the list of children

set root_key_item "${root_key}%"

set item_children ""

db_foreach children_list "
select item_id  as child_id,
       label    as child_title,
       sort_key as child_key,
       length(sort_key)-[string length $root_key]-2 as depth
from   pdm_menu_items
where  item_id <> :item_id
and    menu_id = :menu_id
and    sort_key like :root_key_item
order by child_key" {

    append item_children "[pdm_indentation $depth]
    <a href=item-edit?menu_id=$menu_id&item_id=$child_id>$child_title</a><br>"

} if_no_rows {

    set item_children "None"
}

# -----------------------------------------------------------------------------



doc_return  200 text/html "
[ad_header_with_extra_stuff $page_title]

<h2>$page_title</h2>

[ad_context_bar_ws [list "" "Pull-Down Menu"] $page_title]
<hr>

<form method=post action=item-edit-2>

[export_form_vars item_id menu_id]

<table>

<tr>
<th align=right>Label:</th>
<td><input type=text size=40 maxlength=100 name=label value=\"[ad_quotehtml $label]\"></td>
</tr>

<tr>
<th align=right>URL:</th>
<td><input type=text size=40 maxlength=500 name=url value=\"$url\"></td>
</tr>

<tr>
<td></td>
<td><input type=submit value=\"Submit\"></td>
</tr>

</table>

</form>

<h4>Parent</h4>
<ul>
$item_parent
</ul>
<h4>Subitems</h4>
<ul>
$item_children
</ul>
<h4>Extreme Actions</h4>
<ul>
<a href=item-delete?[export_url_vars item_id]>Delete this item</a>
</ul>
[ad_admin_footer]"

