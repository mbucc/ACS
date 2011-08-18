# $Id: category-one.tcl,v 3.0.4.1 2000/03/17 23:10:10 jsalz Exp $
# File:     admin/calendar/category-one.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  shows one category  

set_the_usual_form_variables

# category_id

set db [ns_db gethandle]

set category [database_to_tcl_string $db "
select category
from calendar_categories 
where category_id=$category_id "]

set selection [ns_db 1row $db "
select scope, group_id
from calendar_categories
where category_id = $category_id "]

set_variables_after_query

ns_log "Warning" "Seems to me the scope is <$scope>"

if { $scope=="group" } {
    set short_name [database_to_tcl_string $db "select short_name
                                                from user_groups
                                                where group_id = $group_id"]    
}

if { $scope != "group" } {
    set admin_url_string "/calendar/admin/category-one.tcl?category_id=$category_id&scope=$scope"
} else {
    set admin_url_string "/groups/admin/$short_name/calendar/category-one.tcl?category_id=$category_id&scope=$scope&group_id=$group_id"
}

ReturnHeaders

ns_write "
[ad_admin_header "Category $category"]
<h2>Category $category</h2>
[ad_admin_context_bar [list "index.tcl" "Calendar"] [list "categories.tcl" "Categories"] "One Category"]  

<hr>

<table>
<tr>
 <td align=right> Maintainer Page:</td>
 <td> <a href=$admin_url_string>$admin_url_string</a></td>
</tr>
</table>

<ul>
"

set selection [ns_db select $db "select calendar.*, expired_p(expiration_date) as expired_p
from calendar
where  category_id = $category_id
order by expired_p, creation_date desc"]

set counter 0 
set expired_p_headline_written_p 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter 
    if { $expired_p == "t" && !$expired_p_headline_written_p } {
	ns_write "<h4>Expired Calendar Items</h4>\n"
	set expired_p_headline_written_p 1
    }
    ns_write "<li>[util_AnsiDatetoPrettyDate $start_date] - [util_AnsiDatetoPrettyDate $end_date]: <a href=\"item.tcl?calendar_id=$calendar_id\">$title</a>"
    if { $approved_p == "f" } {
	ns_write "&nbsp; <font color=red>not approved</font>"
    }
    ns_write "\n"
}

ns_write "
<P>
</ul>
[ad_admin_footer]
"

