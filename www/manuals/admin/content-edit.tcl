# /www/manuals/admin/content-edit.tcl
ad_page_contract {
    Page to allow the editing of manual pages through the web interface

    @param manual_id the manual we are working on
    @param section_id the ID of the section being edited
    @param comment a version control comment (if this isn't the first time)
    @param conflict was there a conflict in CVS?
    @param new were we thrown here because of bad newly uploaded content?
    @param new_list info to go in the db

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id content-edit.tcl,v 1.5.2.4 2000/08/06 21:58:45 kevin Exp
} {
    manual_id:integer,notnull
    section_id:integer,notnull
    {comment:html ""}
    {conflict "f"}
    {new "f"}
    {new_list ""}
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

# Grab the existing content from the database unless we got kicked here
# from an upload of new content, in which case there is no database entry
# yet.

if { $new == "f"} {
    page_validation {
	if { ![db_0or1row manual_section_info "
	select m.title, 
	       s.section_title, 
	       s.content_p
	from   manuals m, 
	       manual_sections s
	where  m.manual_id   = :manual_id
	and    s.section_id  = :section_id"] } {

	    error "Section id=$section_id does not exist."
	}
    }

} else {
    db_1row title "select title from manuals where manual_id = :manual_id"

    set section_title [lindex [split $new_list ","] 0]
    set content_p "t"
}

db_release_unused_handles

# Are we being bounced back by content-edit-2.tcl because of a CVS conflict?

if {$conflict == "t" } {
    set conflict_string "
    <p>Your changes conflict with changes someone else made while you were
    editing.  The conflicting region is marked below using:
    <pre>
    <<<<<<<
    changes somebody else made
    =======
    changes you made
    >>>>>>>
    <pre>
    <p>You must resolve the conflict and resubmit the file.</p>"

    # We really ought to tell them who the other person was
} else {
    set conflict_string ""
}


if {$content_p == "t"} {
    
    # Make sure the content file exists

    set content_file ${manual_id}.${section_id}.html
    set content_path [ns_info pageroot]/manuals/sections/$content_file

    page_validation {
	if ![file exists $content_path] {
	error "The file associated with this section does not exist!<br>$content_path" 
	}
    }

    # Retrieve the contents of this section

    if [ad_parameter UseCvsP manuals] {

	set editors_dir [ns_info pageroot]/manuals/admin/editors/$user_id
	set module [vc_path_to_module $content_path]

	# Checkout of a copy of the file for the editor
	if {$conflict == "f"} {
	    page_validation {
		if [vc_checkout $module $editors_dir] {
		    #an error occurred
		    error "We had a problem with the CVS checkout of this file.  Are you sure you have CVS set up properly?"
		}
	    }
	}

	# Read the editor's file
	set stream  [open $editors_dir/$content_file r]
	set content [read $stream]
	close $stream
    } else {
	# Not using CVS - open the real file
	set content [manual_get_content $manual_id $section_id]
    }

} else {
    set content ""
}

# Leaving the content-edit.tcl page by any other means will not really
# create a problem, but we'll offer the user the opportunity to clean
# up the editor's copies by passing through a special abort page.
#
# if they uploaded bad content, they don't get to escape until they
# fix it.

if { $new == "f" } {
    set abort_message "
    <p><a href=content-edit-abort?[export_url_vars section_id manual_id]>
    I don't want to edit this section after all.</a></p>"
} else {
    set abort_message ""
}

# -----------------------------------------------------------------------------

doc_set_property title "Edit Content for \"$section_title\""
doc_set_property navbar [list \
	[list "../" [manual_system_name]] \
	[list "index.tcl" "Admin"] \
	[list "manual-edit.tcl?manual_id=$manual_id" $title] "Edit Content"]

doc_body_append "

$conflict_string

$abort_message

<form action=content-edit-2 method=post>
[export_form_vars section_id manual_id new new_list]

<table>

<tr>
<th valign=top align=right>Content:</th>
<td><textarea name=content rows=40 cols=80 wrap=soft>$content</textarea>
</tr>

<tr>
<th align=right>Log Message:</th>
<td><input type=text name=comment size=60 value=\"$comment\"></td>
</tr>

<tr>
<td></td>
<td><input type=submit value=Submit></td>
</tr>

</table>
</form>

$abort_message

"
