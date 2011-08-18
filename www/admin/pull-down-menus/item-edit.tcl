# /admin/pull-down-menus/item-edit.tcl
#
# by aure@arsdigita.com
#
# 2000-02-18
#
# Allows the user the edit the parameters for a item
#
# $Id: item-edit.tcl,v 1.1.2.2 2000/03/25 21:44:43 aure Exp $
# -----------------------------------------------------------------------------

ad_page_variables {item_id menu_id}

set page_title "Edit Item"

# -----------------------------------------------------------------------------

set db [ns_db gethandle]

# Get the data for this item

set selection [ns_db 1row $db "
select label,
       url,
       menu_id,
       sort_key as root_key
from   pdm_menu_items
where  item_id = $item_id"]
set_variables_after_query

# Get this item's parent

set parent_key [string range $root_key 0 [expr [string length $root_key]-3]]

set selection [ns_db 0or1row $db "
select label as parent_title,
       item_id    as parent_id
from   pdm_menu_items
where  sort_key  = '$parent_key'
and    menu_id = $menu_id"]

if [empty_string_p $selection] {
    set item_parent "Top Level"
} else {
    set_variables_after_query
    set item_parent "<a href=item-edit?menu_id=$menu_id&item_id=$parent_id>
    $parent_title</a>"
}

# Get the list of children

set selection [ns_db select $db "
select item_id  as child_id,
       label    as child_title,
       sort_key as child_key,
       length(sort_key)-[string length $root_key]-2 as depth
from   pdm_menu_items
where  item_id <> $item_id
and    menu_id = $menu_id
and    sort_key like '${root_key}%'
order by child_key"]

set count 0
set item_children ""
while {[ns_db getrow $db $selection]} {
    incr count
    set_variables_after_query
    append item_children "[pdm_indentation $depth]
    <a href=item-edit?menu_id=$menu_id&item_id=$child_id>$child_title</a><br>"
}

if {$count == 0} {
    set item_children "None"
}

# -----------------------------------------------------------------------------

ns_return 200 text/html "
[ad_header_with_extra_stuff $page_title]

<h2>$page_title</h2>


[ad_context_bar_ws [list "" "Pull-Down Menu"] $page_title]
<hr>

<form method=post action=item-edit-2>

[export_form_vars item_id menu_id]

<table>

<tr>
<th align=right>Label:</th>
<td><input type=text size=40 maxlength=100 name=label value=\"$label\"></td>
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






