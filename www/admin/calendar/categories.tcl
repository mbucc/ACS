# www/admin/calendar/categories.tcl
ad_page_contract {
    Lists categories

    Number of queries: 2

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id categories.tcl,v 3.2.2.5 2001/01/10 16:04:59 khy Exp
    
} {
    {scope public}
    {user_id ""}
    {group_id ""}
    {on_what_id ""}
    {on_which_group ""}
}

## Yikes!  This page lists "Personal" about a hundred times!
## Probably once for each user, I would assume.  Might be 
## smarter to print their username...   -MJS 7/13


# File:     admin/calendar/categories.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  lists all categories  



set page_content "
[ad_admin_header "Calendar categories"]
<h2>Categories</h2>
[ad_admin_context_bar [list "index.tcl" "Calendar"] "Categories"]

<hr>
<blockquote>
"


set query_categories "select category_id, category, enabled_p 
from calendar_categories
order by scope desc, enabled_p desc"

set counter 0
set enabled_headline_shown_p 0
set disabled_headline_shown_p 0

db_foreach categories $query_categories {

    incr counter
    if { $enabled_headline_shown_p == 0 && $enabled_p == "t" } {
	append page_content "
	<h4>Categories in which users can post</h4>
	<ul>"
	set enabled_headline_shown_p 1
    } 

    if { $disabled_headline_shown_p == 0 && $enabled_p == "f" } {
	append page_content "
	</ul>
	<h4>Disabled Categories</h4>
	<ul>"
	set disabled_headline_shown_p 1
    } 

    append page_content "<li><a href=\"category-one?category_id=[ns_urlencode $category_id]\">$category</a>\n"
}

if { $counter == 0 } {
    append page_content "no event categories are currently defined"
}

set category_id [db_string unused "select calendar_category_id_sequence.nextval from dual" ]

append page_content "
<P>
</ul>
<br>
<form action=category-new method=post>
<input type=text name=\"category\" size=20 maxlength=100> 
<input type=submit value=add>
[export_form_vars -sign category_id] 
</form>
</blockquote>
[ad_admin_footer]
"
 
doc_return  200 text/html $page_content

## END FILE categories.tcl







