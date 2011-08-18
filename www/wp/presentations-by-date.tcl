# $Id: presentations-by-date.tcl,v 3.0 2000/02/06 03:55:28 ron Exp $
# File:        presentations-by-date.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Shows a list of public presentations, sorted in reverse by date.
# Inputs:      bulk_copy (optional)

set_the_usual_form_variables 0

ReturnHeaders
ns_write "[wp_header [list "?[export_ns_set_vars]" "WimpyPoint"] "Presentations by Date"]

Here are the public presentations, sorted by creation date.

<ul>
"

set out ""
set db [ns_db gethandle]
wp_select $db "
    select u.user_id, u.last_name, u.first_names,  u.email, wp.presentation_id, wp.title as presentation_title, wp.creation_date, count(ws.slide_id) as n_slides
    from users u, wp_presentations wp, wp_slides ws
    where u.user_id = wp.creation_user
    and wp.presentation_id = ws.presentation_id(+)
    and wp.public_p = 't'
    and ws.max_checkpoint is null
    group by u.user_id, u.last_name, u.first_names, u.email, wp.presentation_id, wp.title, wp.creation_date
    having count(ws.slide_id) > 1
    order by wp.creation_date desc
" {
    if { $n_slides == 0 } {
	set slide_info "no slides"
    } elseif { $n_slides == 1 } {
	set slide_info "one slide"
    } else {
	set slide_info "$n_slides slides"
    }
    if { [info exists bulk_copy] } {
	append out "<li><a href=\"bulk-copy-2.tcl?presentation_id=$bulk_copy&source_presentation_id=$presentation_id\" target=_parent>[ns_striphtml $presentation_title]</a> 
created by <a href=\"one-user.tcl?user_id=$user_id&bulk_copy=$bulk_copy\">$first_names $last_name</a> on [util_IllustraDatetoPrettyDate $creation_date]; $slide_info\n"
    } else {
	append out "<li><a href=\"[wp_presentation_url]/$presentation_id/\">[ns_striphtml $presentation_title]</a> 
created by <a href=\"/shared/community-member.tcl?user_id=$user_id\">$first_names $last_name</a> on [util_IllustraDatetoPrettyDate $creation_date]; $slide_info\n"
    }
}
ns_db releasehandle $db

ns_write "$out
</ul>
[wp_footer]
"

