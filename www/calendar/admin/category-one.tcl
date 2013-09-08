# www/calendar/admin/category-one.tcl
ad_page_contract {
    Lists events in a category, with options to add an event, change the
    category name, or delete the category

    Number of queries: 3

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id category-one.tcl,v 3.2.2.5 2000/09/22 01:37:06 kevin Exp
    
} {
    category_id:naturalnum
    {scope public}
    {user_id:naturalnum ""}
    {group_id:naturalnum ""}
    {on_what_id:naturalnum ""}
    {on_which_group:naturalnum ""}
}

# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

# category_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

ad_scope_authorize $scope admin group_admin none


db_1row category "
select category
from calendar_categories 
where category_id=:category_id "
 
set page_content "
[ad_scope_admin_header "Category $category"]
[ad_scope_admin_page_title "Category <i>$category</i>"]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_scope_vars]" "Calendar"] [list "categories.tcl?[export_url_scope_vars]" "Categories"] "<i>$category</i>"]  

<hr>

<ul>
"


set counter_upcoming 0 
set counter_expired 0

set table_html_upcoming "<H4>Upcoming Events</H4>\n\n<BLOCKQUOTE><TABLE>\n"

set table_html_expired "<H4>Expired Events</H4>\n\n<BLOCKQUOTE><TABLE>\n"

db_foreach events_in_category "
select
start_date,
end_date,
title, approved_p, calendar_id,
expired_p(expiration_date) as expired_p
from calendar c
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



 
if {$counter_upcoming > 0} {
    append page_content $table_html_upcoming "</TABLE></BLOCKQUOTE>\n\n"
}

if {$counter_expired > 0} {
    append page_content $table_html_expired "</TABLE></BLOCKQUOTE>\n\n"
}


append page_content "

<P> 

<li><a href=\"post-new-2?[export_url_scope_vars]&[export_url_vars category category_id]\">Post an event</a>

<p>

<li>

<form method=post action=category-edit>
Change this category name:
[export_form_scope_vars category_id]
<input type=text name=category_new value=\"[philg_quote_double_quotes $category]\">
<input type=submit name=submit value=\"Change\">
</form>"

db_1row category_enabled_p "select enabled_p as category_enabled_p 
from calendar_categories 
where category_id=:category_id"

db_release_unused_handles

if {$category_enabled_p == "t"} {
    append page_content "<li> <A href=\"category-delete?[export_url_scope_vars]&category_id=[ns_urlencode $category_id]\">Delete this category</a>"
} else {
    append page_content "<li> <A href=\"category-enable-toggle?[export_url_scope_vars]&category_id=[ns_urlencode $category_id]\">Allow users to post to this category</a>"
}
append page_content "</ul>
[ad_scope_admin_footer]
"

doc_return  200 text/html $page_content

## END FILE category-one.tcl

