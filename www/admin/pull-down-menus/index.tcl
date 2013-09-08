# /www/admin/pull-down-menus/index.tcl
ad_page_contract {

  Presents a list of all the pdm_menus and gives the option to add a new menu.

  @author aure@arsdigita.com
  @creation-date February 2000
  @cvs-id index.tcl,v 1.4.2.4 2000/09/22 01:35:52 kevin Exp
} {
}

set page_title "Pull-Down Menu Administration"

set html "
[ad_admin_header $page_title]

<h2>$page_title</h2>

[ad_admin_context_bar "Pull-Down Menus"]

<hr>

Documentation: <a href=/doc/pull-down-menus>/doc/pull-down-menus.html</a>

<p>Available menus:

<ul>"


# select information about all of the menus in the system

db_foreach get_all_menus "
select   p.menu_id,
         menu_key,
         default_p,
         count(item_id) as number_of_items
from     pdm_menus p, pdm_menu_items i
where    p.menu_id = i.menu_id(+)
group by p.menu_id, p.menu_key, p.default_p
order by p.menu_key" {

    if {$default_p == "t"} {
	set default_text "(default)"
    } else {
	set default_text ""
    }

    append html "
    <li><a href=items?menu_id=$menu_id>$menu_key</a> 
    ($number_of_items items) $default_text"

} if_no_rows {

    append html "There are no pull-down menus in the database."
}

append html "
<p>
<li><a href=pdm-add>Add a new pull-down menu</a>
</ul>
[ad_admin_footer]"


doc_return  200 text/html $html 

