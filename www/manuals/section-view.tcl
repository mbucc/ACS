# /www/manuals/section.tcl
ad_page_contract {
    View contents of a given section

    @param manual_id the ID of the manual containing this section
    @param section_id the ID of the section we are viewing

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id section-view.tcl,v 1.5.2.3 2000/07/21 04:02:43 ron Exp
} {
    manual_id:integer,optional
    section_id:integer,notnull
}

# -----------------------------------------------------------------------------

# get manual_id if it wasn't provided.  this could happen of a section
# of one manual references a section of another manual and invokes
# this page to view the foreign section.

if [empty_string_p $manual_id] {
    db_1row get_manual_id "
    select manual_id from manual_sections 
    where section_id = :section_id"
}

# get general information about the section

db_1row get_info "
    select m.title,
           s.section_title, 
           s.sort_key,
           s.content_p, 
           length(s.sort_key)/2 as depth
    from   manuals m, manual_sections s
    where  s.section_id = :section_id
    and    m.manual_id  = :manual_id
    and    s.manual_id  = :manual_id"


# set up the table of contents for this section

set section_toc [manual_toc -type "full" -prefix $sort_key $manual_id]

# stream in the source for the section

if { $content_p == "t" } {
    set content [manual_parse_section $manual_id $section_id]
} else {
    set content ""
}

# get comments from the database

set comments [ad_general_comments_list $section_id manual_sections $section_title manuals $manual_id]

# generate optional chapter list

if [ad_parameter ListChaptersP manuals] {
    set chapter_list [manual_chapter_list $manual_id]
} else {
    set chapter_list ""
}

# Finally, get information for navigation controls

db_1row neighbor_ids "
select next_section_id, prev_section_id
from   section_neighbors
where  section_id = :section_id"

db_release_unused_handles

set navigation_list [list]
if ![empty_string_p $prev_section_id] {
    lappend navigation_list "
    <a href=\"section-view?manual_id=$manual_id&section_id=$prev_section_id\">Previous</a>"
}

lappend navigation_list "<a href=manual-view?manual_id=$manual_id>Contents</a>"

if ![empty_string_p $next_section_id] {
    lappend navigation_list "
    <a href=\"section-view?manual_id=$manual_id&section_id=$next_section_id\">Next</a>"
}

set navigation_string "<p align=right> [join $navigation_list " | "]"

# -----------------------------------------------------------------------------

doc_set_property title $section_title
doc_set_property navbar [list \
	[list "index.tcl" [manual_system_name]] \
	[list "manual-view.tcl?manual_id=$manual_id" $title] $section_title]

doc_body_append "

$navigation_string

$chapter_list

<p>$content

<br clear=all>

$navigation_string

$comments

"
