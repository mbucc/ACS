# $Id: one-user.tcl,v 3.0 2000/02/06 03:55:02 ron Exp $
# File:        one-user.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Shows a list of presentations by a particular user.
# Inputs:      user_id
#              bulk_copy (if we're selecting a presentation for bulk copy)

set_the_usual_form_variables

# Rename the user_id input to avoid confusion.
set req_user_id $user_id

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]
set selection [ns_db 1row $db "select first_names, last_name, email from users where user_id = $req_user_id"]
set_variables_after_query

if { $user_id == $req_user_id } {
    # Be Englishically correct.
    set noun "You"
    set verb "have"
    set possessive "Your"
    set possessive_lc "your"
} else {
    set noun "$first_names $last_name"
    set verb "has"
    set possessive "<a href=\"/shared/community-member.tcl?user_id=$req_user_id\">$noun</a>'s"
    set possessive_lc $possessive
}

ReturnHeaders
ns_write "[wp_header [list "./?[export_ns_set_vars url user_id]" "WimpyPoint"] "$possessive Presentations"]
<ul>
"

set out ""
set written_collaboration_headline_p 0
wp_select $db "
    select title, presentation_id, creation_user, creation_date, public_p,
           decode(creation_user, $req_user_id, 't', 'f') creator_p,
           users.first_names, users.last_name,
           wp_access(presentation_id, $user_id, 'read', public_p, creation_user, group_id) my_access           
    from   wp_presentations wp, users
    where  users.user_id = creation_user
           and wp_access(presentation_id, $req_user_id, 'write', public_p, creation_user, group_id) is not null
    order by creator_p desc, wp.creation_date desc, upper(wp.title)
" {
    if { $my_access == "" } {
	continue
    }

    if { !$written_collaboration_headline_p && $creator_p == "f" } {
	set written_collaboration_headline_p 1
	append out "<h4>Presentations Created by Others</h4>\n"
    }

    # If bulk copying, clicking the title proceeds to the next step in the bulk-copy operation.
    if { [info exists bulk_copy] } {
	set link "href=\"bulk-copy-2.tcl?presentation_id=$bulk_copy&source_presentation_id=$presentation_id\" target=_parent"
    } else {
	set link "href=\"[wp_presentation_url]/$presentation_id/\""
    }
    append out "<li><a $link>$title</a>, created [util_IllustraDatetoPrettyDate $creation_date]\n"
    if { $my_access != "read" && ![info exists bulk_copy] } {
	# User has write access - let him/her edit (only available if not bulk copying)
	append out " \[ <a href=\"presentation-top.tcl?presentation_id=$presentation_id\">Edit</a> \]\n"
    }
    if { $creator_p == "f" } {
	if { [info exists bulk_copy] } {
	    set href "one-user.tcl?user_id=$creation_user&bulk_copy=$bulk_copy"
	} else {
	    set href "/shared/community-member.tcl?user_id=$user_id"
	}
	append out "(created by <a href=\"$href\">$first_names $last_name</a>)\n"
    }
    if { $public_p == "f" } {
	append out "(private)\n"
    }
}

if { $out == "" } {
    append out "<li>$noun $verb no presentations."
}

if { $user_id == $req_user_id && ![info exists bulk_copy] } {
    append out "<p><li><a href=\"presentation-edit.tcl\">Create a new presentation</a>.\n"
}

ns_db releasehandle $db
ns_write "$out
<li>Search through $possessive_lc presentations for: <input size=30 name=search> <input type=submit value=\"Search\">
</ul>

[wp_footer]"
