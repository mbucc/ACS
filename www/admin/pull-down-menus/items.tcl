# /www/admin/pull-down-menus/items.tcl
ad_page_contract {

  Shows the menu items and allows the administrator
  to add, edit, delete, or arrange items.

  @param menu_id menu for which the admin UI will be diplayed

  @author aure@arsdigita.com
  @creation-date February 2000
  @cvs-id items.tcl,v 1.5.2.6 2000/09/22 01:35:56 kevin Exp

} {

  menu_id:integer

}

set title "Edit Items"



set exists_p [db_0or1row menu_key "
    select
      menu_key
    from   pdm_menus
    where  menu_id = :menu_id" ]

# If there aren't any items just redirect back to the index page

if { !$exists_p } {
    db_release_unused_handles
    ad_returnredirect ""
    return
}

set page_content "

[ad_header_with_extra_stuff "Pull-Down Menus: $title" [ad_pdm $menu_key 5 5 "t"] [ad_pdm_spacer $menu_key]]

<h2>$title</h2>

[ad_admin_context_bar [list "" "Pull-Down Menu"] $menu_key]

<hr>

Pull-Down Menu outline:<p>
<table cellspacing=0 cellpadding=4 border=0>
<tr bgcolor=#eeeeee>
<td>Top &nbsp; &nbsp; &nbsp; &nbsp; </td>
<td colspan=4 align=right><a href=item-add?menu_id=$menu_id>Add a top-level item</a></td>
</tr>
"

set count 0

db_foreach menu_items "
select n1.item_id, n1.label, n1.sort_key, n1.url,
    (select count(*)
    from  pdm_menu_items n2
    where menu_id = :menu_id
    and   n2.sort_key like substr(n1.sort_key,0,length(n1.sort_key)-2)||'__'
    and   n2.sort_key > n1.sort_key) as more_children_p
from   pdm_menu_items n1
where  menu_id = :menu_id
order by n1.sort_key" {

    incr count
    
    if {[expr $count % 2]==0} {
	set color "#eeeeee"
    } else {
	set color "white"
    }
    
    set depth [expr [string length $sort_key]-2]
    append page_content "
    <tr bgcolor=$color>
    <td>[pdm_indentation $depth]<a 
    href=item-edit?[export_url_vars menu_id item_id]>$label</a></td><td><nobr>&nbsp; &nbsp; &nbsp; </td>"

    if {$more_children_p != 0} {
	append page_content "
	<td><a href=item-move-2?[export_url_vars menu_id item_id]&move=down>
	swap with next</a></td>"
    } else {
	append page_content "<td>&nbsp;</td>"
    }

    append page_content  "
    <td>&nbsp;<a href=item-move?[export_url_vars menu_id item_id]>move</a>&nbsp;</td>"
    
    if {$depth < 3} {
	append page_content "
	<td><a href=item-add?menu_id=$menu_id&parent_key=$sort_key>
	add subitem</a></td>"
    } else {
	append page_content "<td>&nbsp;</td>"
    }
    append page_content "</tr>"
}

append page_content "
</table>

<h3>Extreme Actions</h3>
<ul>
<li> <a href=pdm-edit?menu_id=$menu_id>Edit the look and feel of this pull-down menu</a>
<p>
<li> <a href=pdm-delete?menu_id=$menu_id>Delete this pull-down menu</a>
</ul>

[ad_admin_footer]"

# release the database handle

db_release_unused_handles

# serve the page

doc_return  200 text/html $page_content

