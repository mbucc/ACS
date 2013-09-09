# /www/admin/pull-down-menus/one.tcl
ad_page_contract {

  Shows the pdm items and allows the administrator
  to add, edit, delete, or arrange items

  @author aure@arsdigita.com 
  @cvs-id one.tcl,v 1.2.8.4 2000/09/22 01:35:57 kevin Exp

} {

}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set title "Pull-Down Menu System Administration"

proc pdm_spacer {depth} {
    set spacer ""
    for {set i 0} {$i < $depth} {incr i} {
	append spacer "&nbsp;&nbsp;"
    }
    return $spacer
}

# returns 1 if the given sort_key is the highest leaf node, i.e. the
# given not has no siblings with higher sort_keys; returns 0
# otherwise. 

proc pdm_last_child_p {sort_key_list sort_key} {
    set key_length [string length $sort_key]
    set key_next   [format "%0${key_length}d" [expr [string trimleft $sort_key 0]+1]]

    # the given sort_key is the last child if the search comes back
    # with -1 (no such key in the list)

    return [expr [lsearch $sort_key_list $key_next] == -1]
}

proc pdm_toc_local {} {

    set count 0
    set toc "<table cellspacing=2 cellpadding=2 border=0>"

    # get all of the items

    db_foreach all_menu_items "
    select n1.item_id, n1.label, n1.sort_key, n1.url,
           (select count(*)
            from  pdm_menu_items n2
            where   n2.sort_key like substr(n1.sort_key,0,length(n1.sort_key)-2)||'__'
            and   n2.sort_key > n1.sort_key) as more_children_p
    from   pdm_menu_items n1
    order by n1.sort_key" {

	incr count

	if {[expr $count % 2]==0} {
	    set color "#eeeeee"
	} else {
	    set color "white"
	}

	append toc "
	<tr bgcolor=$color>
	<td width=50%>[pdm_spacer [expr [string length $sort_key]-2]]<a 
	href=item-edit?[export_url_vars item_id]>$label</a></td>
	<td align=right>"
	
	if {$more_children_p != 0} {
	    append toc "
	<a href=item-move-2?[export_url_vars item_id]&move=down>
	swap with next</a> |"
	}

	append toc "
	<a href=item-move?[export_url_vars item_id]>
	move</a> |

	<a href=item-add?parent_key=$sort_key>
	add subitem</a>
	</td>
	</tr>"
    }

    append toc "
    <tr>
    <td>&nbsp;</td>
    </tr>
    <tr>
    <td><a href=item-add>Add a top-level item</a>
    </td>
    </tr>
    </table>"

    return $toc
}

# -----------------------------------------------------------------------------



set return_html "

[ad_header_with_extra_stuff "Pull-Down Menus: $title"]

[ad_pdm "" 10 5]
&nbsp;
<h2>$title</h2>

[ad_admin_context_bar $title]

<hr>

<h3> Contents</h3>

[pdm_toc_local]

[ad_admin_footer]"


doc_return  200 text/html $return_html
