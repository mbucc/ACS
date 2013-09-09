# www/admin/calendar/category-one.tcl
ad_page_contract {
    Lists events in a category

    Number of queries: 3

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id category-one.tcl,v 3.2.6.5 2000/09/22 01:34:25 kevin Exp
    
} {
    category_id:naturalnum
    {scope public}
    {user_id:naturalnum ""}
    {group_id:naturalnum ""}
    {on_what_id:naturalnum ""}
    {on_which_group:naturalnum ""}
}

# category-one.tcl,v 3.2.6.5 2000/09/22 01:34:25 kevin Exp
# File:     admin/calendar/category-one.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  shows one category  

# category_id

set query_category_scope_group "
select category, scope, group_id
from calendar_categories 
where category_id=:category_id "

db_1row category_scope_group $query_category_scope_group


if { $scope=="group" } {
    
    set query_group_name "select short_name
    from user_groups
    where group_id = :group_id"    
    
    set short_name [db_string group_name $query_group_name]
    
}

if { $scope != "group" } {

    set admin_url_string "/calendar/admin/category-one.tcl?category_id=$category_id&scope=$scope"

} else {

    set admin_url_string "/groups/admin/$short_name/calendar/category-one.tcl?category_id=$category_id&scope=$scope&group_id=$group_id"

}



set page_content "
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



set counter_upcoming 0 
set counter_expired 0

set table_html_upcoming "<H4>Upcoming Events</H4>\n\n<BLOCKQUOTE><TABLE>\n"

set table_html_expired "<H4>Expired Events</H4>\n\n<BLOCKQUOTE><TABLE>\n"

db_foreach events_in_category "
select start_date, end_date, title, calendar_id, approved_p, 
expired_p(expiration_date) as expired_p
from calendar
where category_id = :category_id
order by expired_p, creation_date desc
" { 

    set pretty_start_date [util_AnsiDatetoPrettyDate $start_date]
    set pretty_end_date [util_AnsiDatetoPrettyDate $end_date]

    ## We use meta_table to store the name of the tcl variable
    ## so we can switch back and forth writing between two html tables

    if { $expired_p == "f" } {
	set meta_table "table_html_upcoming"
	incr counter_upcoming

    } else {
	set meta_table "table_html_expired"
	incr counter_expired
    }

    append [set meta_table] "
    <TR><TD>$pretty_start_date <TD>- <TD ALIGN=RIGHT>$pretty_end_date 
    <TD><a href=\"item?[export_url_scope_vars calendar_id]\">$title</a>"
    
   
    if { $approved_p == "f" } {
	append [set meta_table] "<TD><font color=red>not approved</font></TD>"
    }

    append [set meta_table] "</TR>\n"
}

db_release_unused_handles


 
if {$counter_upcoming > 0} {
    append page_content $table_html_upcoming "</TABLE></BLOCKQUOTE>\n\n"
}



if {$counter_expired > 0} {
    append page_content $table_html_expired "</TABLE></BLOCKQUOTE>\n\n"
}



append page_content "
<P>
</ul>
[ad_admin_footer]
"

doc_return  200 text/html $page_content

## END FILE category-one.tcl