# /admin/pull-down-menus/index.tcl
#
# Author: aure@arsdigita.com, February 2000
#
# Presents a list of all the pdm_menus and gives the option to add a new menu.
#
# $Id: index.tcl,v 1.1.2.1 2000/03/16 05:33:06 aure Exp $
# -----------------------------------------------------------------------------

set page_title "Pull-Down Menu Administration"

set html "
[ad_admin_header $page_title]

<h2>$page_title</h2>

[ad_admin_context_bar "Pull-Down Menus"]

<hr>

Documentation: <a href=/doc/pull-down-menus.html>/doc/pull-down-menus.html</a>

<p>Available menus:

<ul>"

set db [ns_db gethandle]

# select information about all of the menus in the system
set selection [ns_db select $db "
select   p.menu_id,
         menu_key,
         default_p,
         count(item_id) as number_of_items
from     pdm_menus p, pdm_menu_items i
where    p.menu_id = i.menu_id(+)
group by p.menu_id, p.menu_key, p.default_p
order by p.menu_key"]

set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    if {$default_p == "t"} {
	set default_text "(default)"
    } else {
	set default_text ""
    }

    append html "
    <li><a href=items?menu_id=$menu_id>$menu_key</a> 
    ($number_of_items items) $default_text"
    incr count
}

ns_db releasehandle $db

if {$count == 0} {
    append html "There are no pull-down menus in the database."
}

append html "
<p>
<li><a href=pdm-add>Add a new pull-down menu</a>
</ul>
[ad_admin_footer]"

ns_return 200 text/html $html 






