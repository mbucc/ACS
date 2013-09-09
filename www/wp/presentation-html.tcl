# /wp/presentation-html.tcl
ad_page_contract {
    outputs an entire presentation into a single HTML page
    Get Presentation ID and (optionally) version number

    @param presentation_id id of the presentation to output

    @creation-date  07 Mar 2000
    @author Nuno Santos <nuno@arsdigita.com>
    @cvs-id presentation-html.tcl,v 3.4.4.7 2000/09/22 01:39:32 kevin Exp
} {
    {presentation_id:integer,notnull}
}

if { ![regexp {([0-9]+)(-v([0-9]+))?$} $presentation_id all presentation_id version_dot version] } {
    ns_returnnotfound
    return
}

set auth [wp_check_authorization $presentation_id [ad_verify_and_get_user_id] "read"]

# Set up SQL conditions for getting the right versions of the slides
if { $version == "" } {
    set version_condition "max_checkpoint is null"
    set version_or_null "null"
} else {
    set version_condition "wp_between_checkpoints_p(:version, min_checkpoint, max_checkpoint) = 't'"
    set version_or_null $version
}

# Get info about the presentation (collaborators and style)
db_1row wp_pres_info_select "
select  p.title,
        p.page_signature, 
	p.copyright_notice,
        p.creation_user,
	p.style, 
	p.show_modified_p,
	p.group_id,
	u.first_names,
	u.last_name
from   wp_presentations p, users u
where  p.presentation_id = :presentation_id
 and    p.creation_user = u.user_id"

# Set up html for collaborators
set collaborators ""
db_foreach wp_sel_collab_info "
select u.first_names 
        collaborator_first, 
        u.last_name collaborator_last, 
        u.user_id collaborator_user
from   users u, user_group_map m
where  m.group_id = :group_id
and    (m.role = 'write' or m.role = 'admin')
and    m.user_id = u.user_id
" {
    lappend collaborators "<a href=\"/shared/community-member?user_id=$collaborator_user\">$collaborator_first $collaborator_last</a>"
}
if { [llength $collaborators] != 0 } {
    if { [llength $collaborators] <= 2 } {
	set collaborators_str "<br>in collaboration with [join $collaborators " and "]"
    } else {
	set collaborators [lreplace $collaborators end end "and [lindex $collaborators end]"]
	set collaborators_str "<br>in collaboration with [join $collaborators ", "]"
    }
} else {
    set collaborators_str ""
}

if { [regexp {wp_back=([^;]+)} [ns_set get [ns_conn headers] Cookie] all back] } {
    set back [ns_urldecode $back]
} else {
    set back "../../"
}

# See if the user has overridden the style preferences.
regexp {wp_override_style=(-?[0-9]+)} [ns_set get [ns_conn headers] Cookie] all style

if { $style == "" } {
    set style -1
}

db_1row wp_sel_style_info "
select  text_color,
	background_color,
	background_image,
	link_color,
	vlink_color,
	alink_color
	from wp_styles where style_id = :style"

# Select all of the slides for this presentation
if { $version == "" } {
    set slides_sql "
    select title, preamble, bullet_items, postamble, include_in_outline_p, modification_date, slide_id,
    nvl(original_slide_id, slide_id) original_slide_id
    from   wp_slides
    where  presentation_id = :presentation_id
     and   $version_condition
    order by sort_key
    "
} else {
    set slides_sql "
    select  s.title,\
	    s.preamble,\
	    s.bullet_items,\
	    s.postamble,\
	    s.include_in_outline_p,\
	    s.modification_date,\
	    slide_id,\
	    nvl(s.original_slide_id, s.slide_id) original_slide_id
    from   wp_slides s, wp_historical_sort h
    where  s.presentation_id = :presentation_id
     and h.checkpoint = :version
     and $version_condition
    order by h.sort_key
    "
}
set slides [db_list_of_lists wp_sel_slides $slides_sql]

# Start setting up page
set whole_page "
<html>
<head>
  <title>$title</title>
</head>
<body>
<h2>$title</h2>
a <a href=\"$back\">WimpyPoint</a> presentation owned by <a href=\"/shared/community-member?user_id=$creation_user\">$first_names $last_name</a> $collaborators_str
<hr>
<ul>
"

# How should we get a list of slides in the presentation? Depends on
# whether we're looking at the most recent version, or a historical
# copy.
if { $version == "" } {
    set sql "
    select slide_id id, title slide_title
    from wp_slides
    where presentation_id = :presentation_id
    and   $version_condition
    order by sort_key
    "
} else {
    set sql "
    select s.slide_id id, 
           s.title slide_title
    from wp_slides s, wp_historical_sort h
    where s.slide_id = h.slide_id
    and   h.checkpoint = $version
    and   s.presentation_id = :presentation_id
    and   $version_condition
    order by h.sort_key
    "
}
db_foreach wp_slides $sql {
    append whole_page "    <li>"
    append whole_page "<a href=\"#$id\">$slide_title</a>\n"
}
append whole_page "</ul><hr>"

set counter 0
while {$counter < [llength $slides]} {
    set slide                [lindex $slides $counter]
    set title          	     [lindex $slide 0]
    set preamble       	     [lindex $slide 1]
    set bullet_items   	     [lindex $slide 2]
    set postamble            [lindex $slide 3]
    set include_in_outline_p [lindex $slide 4]
    set modification_date    [lindex $slide 5]
    set slide_id             [lindex $slide 6]
    set original_slide_id    [lindex $slide 7]

    # Get attachments, if any.
    set attach [list]
    db_foreach wp_attach_select "
    select attach_id, file_size, file_name, display
    from   wp_attachments
    where  slide_id = :slide_id
    order by lower(file_name)
    " {
	lappend attach [list $attach_id $file_size $file_name $display]
    }
    
    append whole_page "
    <a name=\"$slide_id\">
    <h2>$title</h2>
    <hr>
    [wp_show_attachments $attach "" "link"]
    
    [wp_show_attachments $attach "top" "center"]
    [wp_show_attachments $attach "preamble" "right"]
    
    $preamble
    [wp_break_attachments $attach "preamble"]
    [wp_show_attachments $attach "after-preamble" "center"]
    "
    
    append whole_page "
    [wp_show_attachments $attach "bullets" "right"]
    [expr { $bullet_items != "" ? "<ul>\n<li>[join $bullet_items "<li>\n"]\n" : ""}]
    "
    
    append whole_page [wp_break_attachments $attach "bullets"]
    
    append whole_page "
    [expr { $bullet_items != "" ? "</ul>" : "</p>" }]
    "
    append whole_page [wp_show_attachments $attach "after-bullets" "center"]
    
    append whole_page "
    [wp_show_attachments $attach "postamble" "right"]
    
    $postamble
    
    [wp_break_attachments $attach "postamble"]
    [wp_show_attachments $attach "bottom" "center"]
    "
    # insert spacer between slides
    append whole_page "
    <pre>
    
    
    
    </pre>"
    
    incr counter
}

append whole_page  "
[expr { $show_modified_p == "t" ? "<p><i>Last modified $modification_date</i>" : "" }]
[expr { $copyright_notice != "" ? "<p>$copyright_notice" : "" }]

[wp_slide_footer $presentation_id $page_signature]
"



doc_return  200 text/html "
[wp_slide_header $presentation_id $title $style $text_color $background_color $background_image $link_color $vlink_color $alink_color]

$whole_page"

