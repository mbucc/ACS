# /www/curriculum/index.tcl

ad_page_contract {
    explains to the user why the publisher has established
    a curriculum and offers links to all the elements
    /curriculum/index.tcl
    
    @author Philip Greenspun (philg@mit.edu)
    @creation-date October 6, 1999
    @cvs-id index.tcl,v 3.2.2.5 2000/09/22 01:37:18 kevin Exp
    
} {}

if { [ad_get_user_id] != 0 } {
    set new_cookie [curriculum_sync]
    if ![empty_string_p $new_cookie] {
	ns_set put  [ns_conn outputheaders] "Set-Cookie" "CurriculumProgress=$new_cookie; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
    }
}

# don't cache this page in case user is coming back here to check
# progress bar 

ns_set put [ns_conn outputheaders] "Pragma" "no-cache"

#ReturnHeadersNoCache

set body "[ad_header "Curriculum" ]

<h2>Curriculum</h2>

[ad_context_bar_ws_or_index "Curriculum"]

<hr>

The publisher of [ad_system_name] has decided that new users wanting
to improve their skills ought to read the following items:

<ol>

"



#set selection [ns_db select $db ] 

set counter 0
db_foreach get_curric_info "select curriculum_element_id, one_line_description, full_description from curriculum order by element_index" {

    incr counter
    append items "<li><a href=\"clickthrough?[export_url_vars curriculum_element_id]\">$one_line_description</a>\n"
    if ![empty_string_p $full_description] {
	append items "<blockquote><font size=-1>$full_description</font></blockquote>\n"
    }
}

if { $counter == 0 } {
    append body "<li>There are no curriculum elements in the database right now.<p>"
} else {
    append body  $items
}

append body "

</ol>

The curriculum bar at the bottom of each page shows what you've read.
Once you've gotten through all items, the bar will disappear (i.e.,
you've graduated).  How does the server know?  Your progress is kept
in a browser cookie.  So if you use this service from a friend's
computer, your progress won't be recorded unless you've logged in.

<p>

Options:

<ul>
<li><a href=\"start-over\">start over</a> (erase history)

</ul>

<p>

[ad_footer]"



doc_return  200 text/html $body