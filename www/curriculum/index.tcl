# $Id: index.tcl,v 3.0 2000/02/06 03:37:35 ron Exp $
# /curriculum/index.tcl
#
# by philg@mit.edu on October 6, 1999
#
# explains to the user why the publisher has established
# a curriculum and offers links to all the elements

if { [ad_get_user_id] != 0 } {
    set new_cookie [curriculum_sync]
    if ![empty_string_p $new_cookie] {
	ns_set put  [ns_conn outputheaders] "Set-Cookie" "CurriculumProgress=$new_cookie; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
    }
}

# don't cache this page in case user is coming back here to check
# progress bar 
ReturnHeadersNoCache

ns_write "[ad_header "Curriculum" ]

<h2>Curriculum</h2>

[ad_context_bar_ws_or_index "Curriculum"]

<hr>

The publisher of [ad_system_name] has decided that new users wanting
to improve their skills ought to read the following items:

<ol>

"

set db [ns_db gethandle]

set selection [ns_db select $db "select curriculum_element_id, one_line_description, full_description
from curriculum
order by element_index"] 

set counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
    append items "<li><a href=\"clickthrough.tcl?[export_url_vars curriculum_element_id]\">$one_line_description</a>\n"
    if ![empty_string_p $full_description] {
	append items "<blockquote><font size=-1>$full_description</font></blockquote>\n"
    }
}

if { $counter == 0 } {
    ns_write "<li>There are no curriculum elements in the database right now.<p>"
} else {
    ns_write $items
}

ns_write "

</ol>

The curriculum bar at the bottom of each page shows what you've read.
Once you've gotten through all items, the bar will disappear (i.e.,
you've graduated).  How does the server know?  Your progress is kept
in a browser cookie.  So if you use this service from a friend's
computer, your progress won't be recorded unless you've logged in.

<p>

Options:

<ul>
<li><a href=\"start-over.tcl\">start over</a> (erase history)

</ul>

<p>


[ad_footer]"
