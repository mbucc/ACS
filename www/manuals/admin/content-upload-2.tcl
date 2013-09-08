# /www/manual/admin/content-upload-2.tcl
ad_page_contract {
    receive and save the uploaded file

    @param manual_id the ID of the manual
    @param section_id the ID of the section being uploaded
    @param file_name the name of the uploaded file
    @param comment a version control comment

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Feb 2000
    @cvs-id content-upload-2.tcl,v 1.5.2.5 2000/07/25 05:03:55 kevin Exp
} {
    manual_id:integer,notnull
    section_id:integer,notnull
    file_name:trim,notnull
    file_name.tmpfile:tmpfile
    comment:trim,notnull
}

# -----------------------------------------------------------------------------

# Verify the editor

set user_id [ad_verify_and_get_user_id]

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }

    if {[file size ${file_name.tmpfile}] == 0 } {
	error "The file you specified is either empty or invalid."
    }

}

# -----------------------------------------------------------------------------

# Set the filename and content directory

set filename     ${manual_id}.${section_id}.html
set content_dir  [ns_info pageroot]/manuals/sections
set content_file $content_dir/$filename

# Read the uploaded file

set istream [open ${file_name.tmpfile}]
set content [read $istream]
close $istream

# do error processing on this content

set exception_text [manual_check_content $manual_id $content]

if ![empty_string_p $exception_text] {
    # make them upload an improved file
    # there is some complicated stuff we could do with
    # CVS so they can edit online, but leave that for later.
    
    db_release_unused_handles

    doc_set_property title "Problems with Your File"
    doc_set_property navbar [list]

    doc_body_append "
    There are some problems with your file.  You must fix them and
    upload the new version.

    <ul>
    $exception_text
    </ul>
    "

    return
}

# Quite probably their file has all sorts of head tags and the like
# which will only cause trouble

regexp {<body>(.*)</body>} $content match body

if [exists_and_not_null body] {
    set content $body
}

#Write the content to the correct location

if [ad_parameter UseCvsP manuals] {

    # Do we need to register this file for version control?

    if [file exists $content_file] {
	set add_file_p 0
    } else {
	set add_file_p 1
    }

    set   ostream [open $content_file w]
    puts  $ostream $content
    close $ostream

    if {$add_file_p} {
	vc_add $content_file
    }

    # Get the user's email address and name for the log entry
  
    db_1row user_info "
    select email, 
           first_names || ' ' || last_name as full_name 
    from   users 
    where  user_id = :user_id"

    vc_commit $content_file "Uploaded by $full_name ($email) - $comment"

} else {
    # Not using version control - just write the file
    set ostream [open $content_file w]
    puts  $ostream $content
    close $ostream
}

db_dml section_update "
update manual_sections
set content_p = 't'
where section_id = :section_id"

ad_returnredirect section-edit.tcl?[export_url_vars manual_id section_id]
