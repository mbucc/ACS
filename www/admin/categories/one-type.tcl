# $Id: one-type.tcl,v 3.1 2000/03/09 22:14:56 seb Exp $
#
# /admin/categories/one.tcl
#
# by sskracic@arsdigita.com and michael@yoon.org on October 31, 1999
#
# displays all categories of one category type
#

set_the_usual_form_variables 0

# category_type

if { [info exists category_type] && ![empty_string_p $category_type]} {
    set category_type_criterion "c.category_type = '$QQcategory_type'"
    set page_title $category_type
} else {
    set category_type_criterion "c.category_type is null"
    set category_type ""
    set page_title "None"
}

set db [ns_db gethandle]

set selection [ns_db select $db "select c.category, c.category_id, count(ui.user_id) as n_interested_users
from users_interests ui, categories c
where ui.category_id (+) = c.category_id
and $category_type_criterion
group by c.category, c.category_id
order by n_interested_users desc"]

set category_list_html ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append category_list_html "<li><a href=\"one.tcl?[export_url_vars category_id]\">$category</a>\n"

    if {$n_interested_users > 0} {
	append category_list_html " (number of interested users: <a href=\"/admin/users/action-choose.tcl?[export_url_vars category_id]\">$n_interested_users</a>)\n"
    }
}

ns_db releasehandle $db

ReturnHeaders

ns_write "[ad_admin_header $page_title]

<H2>$page_title</H2>

[ad_admin_context_bar [list "index.tcl" "Categories"] "One category type"]

<hr>

<ul>

$category_list_html

<p>
<li><a href=\"category-add.tcl?[export_url_vars category_type]\">Add a category of this type</a>
</ul>

[ad_admin_footer]
"
