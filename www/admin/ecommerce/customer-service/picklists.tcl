# $Id: picklists.tcl,v 3.0 2000/02/06 03:18:19 ron Exp $
# To add a new picklist, just add an element to picklist_list;
# all UI changes on this page will be taken care of automatically

ReturnHeaders

ns_write "[ad_admin_header "Picklist Management"]
<h2>Picklist Management</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "Picklist Management"]

<hr>
These items will appear in the pull-down menus for customer service data entry.
These also determine which items are singled out in reports (items not in these
lists will be grouped together under \"all others\").

<blockquote>
"

set db [ns_db gethandle]

set picklist_list [list [list issue_type "Issue Type"] [list info_used "Information used to respond to inquiry"] [list interaction_type "Inquired Via"]]

set picklist_counter 0
foreach picklist $picklist_list {
    if { $picklist_counter != 0 } {
	ns_write "</table>
	</blockquote>
	"
    }
    ns_write "<h3>[lindex $picklist 1]</h3>
    <blockquote>
    <table>
    "

    set selection [ns_db select $db "select picklist_item_id, picklist_item, picklist_name, sort_key
    from ec_picklist_items
    where picklist_name='[DoubleApos [lindex $picklist 0]]'
    order by sort_key"]
    
    set picklist_item_counter 0
    set old_picklist_item_id ""
    set old_picklist_sort_key ""

    while { [ns_db getrow $db $selection] } {
	incr picklist_item_counter
	set_variables_after_query
	if { ![empty_string_p $old_picklist_item_id] } {
	    ns_write "<td> &nbsp;&nbsp;<font face=\"MS Sans Serif, arial,helvetica\"  size=1><a href=\"picklist-item-add.tcl?prev_sort_key=$old_sort_key&next_sort_key=$sort_key&picklist_name=[ns_urlencode [lindex $picklist 0]]\">insert after</a> &nbsp;&nbsp; <a href=\"picklist-item-swap.tcl?picklist_item_id=$old_picklist_item_id&next_picklist_item_id=$picklist_item_id&sort_key=$old_sort_key&next_sort_key=$sort_key\">swap with next</a></font></td></tr>"
	}
	set old_picklist_item_id $picklist_item_id
	set old_sort_key $sort_key
	ns_write "<tr><td>$picklist_item_counter. $picklist_item</td>
	<td><font face=\"MS Sans Serif, arial,helvetica\"  size=1><a href=\"picklist-item-delete.tcl?picklist_item_id=$picklist_item_id\">delete</a></font></td>\n"

    }
    
    if { $picklist_item_counter != 0 } {
	ns_write "<td> &nbsp;&nbsp;<font face=\"MS Sans Serif, arial,helvetica\"  size=1><a href=\"picklist-item-add.tcl?prev_sort_key=$old_sort_key&next_sort_key=[expr $old_sort_key + 2]&picklist_name=[ns_urlencode [lindex $picklist 0]]\">insert after</a></font></td></tr>
	"
    } else {
	ns_write "You haven't added any items.  <a href=\"picklist-item-add.tcl?prev_sort_key=1&next_sort_key=2&picklist_name=[ns_urlencode [lindex $picklist 0]]\">Add a picklist item.</a>\n"
    }

    incr picklist_counter
}

if { $picklist_counter != 0 } {
    ns_write "</table>
    </blockquote>
    "
}

ns_write "</blockquote>
[ad_admin_footer]
"
