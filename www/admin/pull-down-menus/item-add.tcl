# /www/admin/pull-down-menus/item-add.tcl
ad_page_contract {

  Add an item to the menu.

  @param menu_id Which menu this item will be added to.
  @param parent_key Determines this item's position in menu hierarchy.

  @author aure@caltech.edu
  @cvs-id item-add.tcl,v 1.2.8.5 2000/09/22 01:35:53 kevin Exp
} {

    menu_id:integer,notnull
    {parent_key ""}

}


if [empty_string_p $parent_key] {
    set parent_label "Top"
} else {
    set parent_label [db_string get_parent_label "
    select label as parent_label
    from   pdm_menu_items
    where  menu_id = :menu_id
    and    sort_key  = :parent_key" ]
}

set title "Add Item"

db_release_unused_handles

# -----------------------------------------------------------------------------

doc_return  200 text/html "[ad_header_with_extra_stuff $title]

<h2>Add Item Under $parent_label</h2>

[ad_context_bar_ws [list "" "Pull-Down Menu"] $title]

<hr>

<form action=item-add-2>

[export_form_vars menu_id parent_key]

<table>
  <tr>
    <th align=right>Label:</th>
    <td><input type=text size=40 name=label></td>
  </tr>
  <tr>
    <th align=right>URL (optional):</th>
    <td><input type=text size=40 maxlength=500 name=url></td>
  </tr>
  <tr>
    <td></td>
    <td><input type=submit value=Submit></td>
  </tr>
</table>
</form>

<p>If the URL is left blank, the menu item will only be used as a place holder for other items.  

[ad_admin_footer]"
