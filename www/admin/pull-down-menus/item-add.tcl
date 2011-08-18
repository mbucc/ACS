# /admin/pull-down-menus/item-add.tcl
#
# Author: aure@caltech.edu
#
# Add an item to the menu
#
# $Id: item-add.tcl,v 1.1.2.1 2000/03/16 05:33:07 aure Exp $
# -----------------------------------------------------------------------------

ad_page_variables {
    {menu_id}
    {parent_key ""}
}

set db [ns_db gethandle]

if [empty_string_p $parent_key] {
    set parent_label "Top"
} else {
    set parent_label [database_to_tcl_string $db "
    select label as parent_label
    from   pdm_menu_items
    where  menu_id = $menu_id
    and    sort_key  = '$parent_key'"]
}

set title "Add Item"

ns_db releasehandle $db

# -----------------------------------------------------------------------------

ns_return 200 text/html "[ad_header_with_extra_stuff $title]

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
