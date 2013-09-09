# /www/admin/manual/section-move.tcl
ad_page_contract {
    Page to rearrange sections

    @param manual_id the ID of the manual we are modifying
    @param section_id the ID of the section we are moving

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Now 1999
    @cvs-id section-move.tcl,v 1.4.2.2 2000/07/21 04:02:56 ron Exp
} {
    manual_id:integer,notnull
    section_id:integer,notnull
}

# ----------------------------------------------------------------

set page_title "Move Section"

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

# get the current section and manual information
db_1row section_info "
    select sort_key, 
           section_title,
           title
    from   manual_sections s, manuals m
    where  s.section_id = :section_id
    and    s.manual_id  = :manual_id
    and    m.manual_id  = :manual_id"

set section_depth 0
set section_list ""

db_foreach section "
select section_id     as parent_id,
       section_title  as parent_title,
       sort_key       as parent_key
from   manual_sections
where  manual_id = :manual_id
and    active_p  = 't'
order by sort_key" {
    
    # Note that we can only descend by a unit amount, but we can
    # acscend by an arbitrary amount.

    if { [string length $parent_key] > $section_depth } {
	append section_list "<ul>\n"
	incr section_depth 2
    } elseif {[string length $parent_key] < $section_depth} {
	while { [string length $parent_key] < $section_depth } {
	    append section_list "</ul>\n"
	    incr section_depth -2
	}
    }

    # A section can't be moved under one of it's own childen, so
    # check so see if the current section is a child of the one we're
    # moving 

    if {[regexp "^$sort_key" $parent_key match] } {
	append section_list "<li>$parent_title\n"
    } else {
	append section_list "<li>
	<a href=section-move-2?[export_url_vars manual_id section_id parent_id]>
	$parent_title</a>\n"
    }
}

# Make sure we get back to zero depth

while {$section_depth > 0} {
    append section_list "</ul>\n"
    incr   section_depth -2
}

db_release_unused_handles

# -----------------------------------------------------------------------------

doc_set_property title $page_title
doc_set_property navbar [list \
	[list "../" [manual_system_name]] \
	[list "index.tcl" "Admin"] \
	[list "manual-view.tcl?manual_id=$manual_id" $title] "Move Section"]

doc_body_append "

<p>Click on the section that you would like to move \"$section_title\" 
under, or on \"Top\" to make it a top level section.

<blockquote>
<a href=\"section-move-2?[export_url_vars manual_id section_id]\">Top</a>
<p>$section_list</p>
</blockquote>
<p>

"




