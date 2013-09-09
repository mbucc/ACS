# /wp/presentation-top.tcl
ad_page_contract {
    Top level for editing a presentation.
    @cvs-id presentation-top.tcl,v 3.4.2.13 2000/09/22 01:39:34 kevin Exp
    @creation-date  28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @param presentation_id - ID of the presentation
    @param new_slide_id - ID of a slide just created, to call special attention to it.
} {
    presentation_id:naturalnum,notnull
    new_slide_id:naturalnum,optional
}

# modified by jwong@arsdigita.com on 10 Jul 2000 for ACS 3.4 upgrade


proc_doc wp_access { presentation_id user_id { priv "read" } } { Returns the user's actual level, if the user can perform $priv roles on the presention. } {
    return [db_string wp_sel_access_info "
        select wp_access(presentation_id, :user_id, :priv, public_p, creation_user, group_id)
        from wp_presentations
        where presentation_id = :presentation_id
    " -default "not_found" ]
}

proc_doc wp_check_authorization { presentation_id user_id { priv "read" } } { Verifies that the user can perform $priv roles on the presentation, returning an error and bailing if not. If authorized, returns the level at which the user is actually authorized. } {
    set auth [wp_access $presentation_id $user_id $priv]
    if { $auth == "" } {
	ad_return_error "Authorization Failed" "You do not have the proper authorization to access this feature."
	ad_script_abort
    } elseif {	$auth == "not_found" } {
	ad_return_error "Error" "Presentation $presentation_id was not found in the database."
	ad_script_abort
    } else {
	return $auth
    }
}
if { ![info exists new_slide_id] } {
    set new_slide_id -1
}

set user_id [ad_maybe_redirect_for_registration]

set auth [wp_check_authorization $presentation_id $user_id "write"] 

db_1row pres_select "
    select  title, 
            public_p, 
       	    audience, 
	    background, 
	    group_id
    from wp_presentations where presentation_id = :presentation_id" 

set page_output [wp_header [list "" "WimpyPoint"] [list "index.tcl?show_user=" "Your Presentations"] "$title"]

append page_output "
<h3>The Slides</h3>
"

set out "<table cellspacing=0 cellpadding=0>"
set counter 0
set last_sort_key 0

db_foreach slide_select "
    select slide_id, title, sort_key
    from wp_slides 
    where presentation_id = :presentation_id
    and max_checkpoint is null
    order by sort_key
" {
    incr counter

    # If a slide was just added, make it bold to provide some visual feedback.
    if { $slide_id == $new_slide_id } {
	set bold_if_new "<b>"
    } else {
	set bold_if_new ""
    }
    append out "
<tr valign=top>
  <td align=right nowrap><spacer type=vertical size=4>$bold_if_new$counter.&nbsp;</td>
  <td><spacer type=vertical size=4>$bold_if_new<a href=\"[wp_presentation_edit_url]/$presentation_id/$slide_id.wimpy\">$title</a></td>
  <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td nowrap><spacer type=vertical size=4>&nbsp;\[ <a href=\"slide-edit?slide_id=$slide_id\">edit</a> | <a href=\"slide-delete?slide_id=$slide_id\">delete</a> | <a href=\"slide-attach?slide_id=$slide_id\">attach</a> \]</td>
  <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td nowrap><font size=-1>&nbsp;&nbsp;<img src=\"pics/arrow.gif\" align=top> <a href=\"slide-edit?presentation_id=$presentation_id&sort_key=$sort_key\">Insert</a></td>
</tr>
"
    set last_sort_key $sort_key
}

if { $counter == 0 } {
    # No slides yet.
    set out "<ul><li><a href=\"slide-edit?presentation_id=$presentation_id&sort_key=1\">Create the first slide</a></ul>\n"
} else {
    append out "
<tr valign=top><td></td>
  <td><spacer type=vertical size=4><a href=\"reorder-slides?presentation_id=$presentation_id\">Change order of slides</a></td>
  <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td></td>
  <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
  <td><font size=-1>&nbsp;&nbsp;<img src=\"pics/arrow.gif\" align=top> <a href=\"slide-edit?presentation_id=$presentation_id&sort_key=[expr $last_sort_key + 1]\">Add</a></td></tr>\n"
    append out "</table>"
}

# Generate a <select> list of all checkpoints. The greatest checkpoint represents the current
# state of the presentation, and so shouldn't be listed here.
set previous_versions "<p><li>Previous versions of this presentation:<br>
<select name=version>
"
set counter 0
db_foreach checkpoint_select "
    select checkpoint, description, TO_CHAR(checkpoint_date, 'Mon. DD, YYYY, HH:MI A.M.') checkpoint_date
    from wp_checkpoints
    where presentation_id = :presentation_id
    order by checkpoint desc
" {
    if { $counter != 0 } {
	# Skip the latest checkpoint
	append previous_versions "<option value=\"$checkpoint\">$description ($checkpoint_date)\n"
    }
    incr counter
}
if { $counter <= 1 } {
    # Just one checkpoint - don't display the menu.
    set previous_versions ""
} else {
    append previous_versions "</select><br>
<input type=button value=\"Show\" onClick=\"with (form.version) location.href='[wp_presentation_url]/$presentation_id-v'+options\[selectedIndex\].value+'/'\">
<input type=button value=\"Show w/Comments\" onClick=\"with (form.version) location.href='[wp_presentation_edit_url]/$presentation_id-v'+options\[selectedIndex\].value+'/'\">
"
    if { $auth == "admin" } {
	append previous_versions "<input type=button value=\"Revert to This Version\" onClick=\"with (form.version) location.href='presentation-revert.tcl?presentation_id=$presentation_id&checkpoint='+options\[selectedIndex\].value\">"
    }
}

append out "
</table>

<h3>Options</h3>

<ul>

<li><a href=\"[wp_presentation_url]/$presentation_id/\">Show presentation</a>
<li><a href=\"[wp_presentation_edit_url]/$presentation_id/\">Show presentation, viewing comments from collaborators and &quot;edit&quot; links</a>

<p>

<li><a href=\"presentation-edit?presentation_id=$presentation_id\">Edit presentation properties</a>
<li><a href=\"outline-adjust?presentation_id=$presentation_id\">Adjust outline and context breaks</a><p>

<li>Bulk copy slides from
<a href=\"bulk-copy?presentation_id=$presentation_id&user_id=$user_id\">one of your presentations</a> or
<a href=\"bulk-copy?presentation_id=$presentation_id\">another user's presentation</a>

[wp_only_if {[ad_parameter "AllowBulkUploadP" "wp" 1] && [file exists [ad_parameter "PathToUnzip" "wp" "/usr/bin/unzip"]]} "
<li><a href=\"bulk-image-upload?presentation_id=$presentation_id\">Upload an archive of images</a>
"]

[wp_only_if { $auth == "admin" } "
<p>
<li><a href=\"presentation-delete?presentation_id=$presentation_id\">Delete this presentation</a>
"]

</ul>

<h3>Viewers / Collaborators</h3>

<ul>
"

if { $public_p == "t" } {
    append out "<li>Everyone can view the presentation, since it is public.\n"
    set role_condition "and role in ('write','admin')"
} else {
    set role_condition ""
}

db_foreach collaborators_select "
    select u.first_names, u.last_name, u.user_id his_user_id, m.role
    from users u, user_group_map m
    where m.group_id = :group_id
    and   m.user_id = u.user_id $role_condition
    order by decode(m.role, 'read', 0, 1), lower(u.last_name), lower(u.first_names)
" {
    append out "<li><a href=\"/shared/community-member?user_id=$his_user_id\">$first_names $last_name</a> "
    if { $role == "read" } {
	append out " (read-only)\n"
    }
} else {
    if { $public_p == "f" } {
	append out "<li>None.\n"
    }
}

db_release_unused_handles

if { $auth == "admin" } {
    append out "<li><a href=\"presentation-acl?presentation_id=$presentation_id\">Change people who can view/edit this presentation</a>\n"
}
append out "</ul>\n"

if { $auth == "admin" || $previous_versions != "" } {
    append out "<h3>Versioning</h3>
<ul>
$previous_versions
<li><a href=\"presentation-freeze?presentation_id=$presentation_id\">Freeze the current slide set</a> (create a new version)
</ul>
"
}

append page_output "$out

[wp_only_if { ![empty_string_p $audience] } "<h3>Audience</h3>\n$audience</p>\n"]
[wp_only_if { ![empty_string_p $background] } "<h3>Background</h3>\n$background</p>\n"]

[wp_footer]
"

doc_return  200 "text/html" $page_output
