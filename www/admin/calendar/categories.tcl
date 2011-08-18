# $Id: categories.tcl,v 3.0 2000/02/06 03:08:59 ron Exp $
# File:     admin/calendar/categories.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  lists all categories  

ReturnHeaders

ns_write "
[ad_admin_header "Calendar categories"]
<h2>Categories</h2>
[ad_admin_context_bar [list "index.tcl" "Calendar"] "Categories"]

<hr>
<ul>
"

set db [ns_db gethandle]
set selection [ns_db select $db "select category_id, category, enabled_p 
from calendar_categories
order by scope desc,enabled_p desc"]

set counter 0
set enabled_headline_shown_p 0
set disabled_headline_shown_p 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    if { $enabled_headline_shown_p == 0 && $enabled_p == "t" } {
	ns_write "
	<h4>Categories in which users can post</h4>
	<ul>"
	set enabled_headline_shown_p 1
    } 

    if { $disabled_headline_shown_p == 0 && $enabled_p == "f" } {
	ns_write "
	</ul>
	<h4>Disabled Categories</h4>
	<ul>"
	set disabled_headline_shown_p 1
    } 

    ns_write "<li><a href=\"category-one.tcl?category_id=[ns_urlencode $category_id]\">$category</a>\n"
}

if { $counter == 0 } {
    ns_write "no event categories are currently defined"
}

set category_id [database_to_tcl_string $db "select calendar_category_id_sequence.nextval from dual" ]

ns_write "
<P>
</ul>
</ul>

[ad_admin_footer]
"
 


