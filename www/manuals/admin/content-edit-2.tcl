# /www/manual/admin/section-edit-2.tcl

ad_page_contract {
    This page processes the edited content.

    @param manual_id the ID of the manual we are working with
    @param section_id the ID of the section being modified
    @param content the new contents of the section
    @param comment a version control comment
    @param new is this a newly created page with bad content?
    @param new_list the info to shove in the db

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Feb 2000
    @cvs-id content-edit-2.tcl,v 1.4.2.4 2000/07/25 09:20:18 ron Exp
} {
    {manual_id:integer,notnull}
    {section_id:integer,notnull}
    {content:allhtml}
    {comment:allhtml}
    {new "f"}
    {new_list ""}
}

# -----------------------------------------------------------------------------

# Verify the editor

set user_id [ad_verify_and_get_user_id]

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

# Various file names that we'll need in the processing below

set content_file  ${manual_id}.${section_id}.html
set content_dir   [ns_info pageroot]/manuals/sections
set content_path  $content_dir/$content_file
set editors_dir   [ns_info pageroot]/manuals/admin/editors/$user_id/
set editors_path  $editors_dir/$content_file

# -----------------------------------------------------------------------------

# Helper proc to commit and update the content file

proc manual_commit_and_update {user_id comment editors_path content_path} {
    db_1row user_info "
    select email, 
           first_names || ' ' || last_name as name from users 
    where  user_id = :user_id"

    vc_commit $editors_path "Modified by $name ($email) - $comment"
    vc_update $content_path
    exec rm $editors_path
}

# Helper proc to release the editors copy and update the content file

proc manual_release_and_update {editors_path content_path} {
    vc_update $content_path
    exec rm $editors_path
}

# -----------------------------------------------------------------------------

# look for problems in the content

set exception_text [manual_check_content $manual_id $content]

page_validation {
    if ![empty_string_p $exception_text] {
	error $exception_text
    }
}

# -----------------------------------------------------------------------------
# Done with error checking.  The content is OK so we can update the
# editor's file.

if [ad_parameter UseCvsP manuals] {

    # write the content of the post to the editor's copy of the file
    set ostream [open $editors_path w]
    puts  $ostream $content
    close $ostream

    # get the vc file properties
    regexp {Status: *([ a-zA-Z-]+)} [vc_status $editors_path] match status
    global vc_file_props
    vc_file_props_init $editors_path
    #vc_parse_cvs_status [vc_fetch_status $editors_path]

# CVS will come back with one of the following status messages:
# 
# Up-to-date 
#        The file is identical with the latest revision in the
#        repository for the branch in use. 
#
# Locally Modified 
#        You have edited the file, and not yet committed your changes. 
#
# Needs Checkout 
#        Someone else has committed a newer revision to the
#        repository. The name is slightly misleading; you will
#        ordinarily use update rather than checkout to get that newer
#        revision.  
#
# Needs Patch 
#        Like Needs Checkout, but the CVS server will send a patch
#        rather than the entire file. Sending a patch or sending an
#        entire file accomplishes the same thing. 
#
# Needs Merge 
#        Someone else has committed a newer revision to the
#        repository, and you have also made modifications to the file.  
#
# File had conflicts on merge 
#        This is like Locally Modified, except that a previous update
#        command gave a conflict. If you have not already done so, you need
#        to resolve the conflict as described in section Conflicts
#        example. 

    switch -glob $status {
	"Up-to-date" {
	    # nothing to do - they didn't actually edit the file
 	    manual_release_and_update $editors_path $content_path
	}

	"Locally Modified" {
	    # commit the changes
	    manual_commit_and_update $user_id $comment $editors_path $content_path
	}

	"Needs *" -
	"File had conflicts on merge" {
	    # update the local copy and handle potential conflicts
	    vc_update $editors_path
	    #catch { exec $cvs -d $root update $editors_path } errmsg

	    # check the new status - if we generated conflicts during
	    # the merge they will need to be resolved by hand,
	    # otherwise we can simply commit the changes.
	    vc_parse_cvs_status [vc_fetch_status $editors_path]
	    
	    if {[string match "*File had conflicts on merge*" $vc_file_props(status)]} {
		manual_commit_and_update $user_id \
			$comment $editors_path $content_path
	    } else {
		# changes cannot be merged - redirect the editor back
		# to the content-edit.tcl page with the conflict flag
		# set so they can resolve things by hand.
		ad_returnredirect content-edit.tcl?[export_url_vars manual_id section_id comment new new_list]&conflict=t
		return
	    }
	}
	
	default {
	    ad_return_error "manuals" "An error occurred while processing your commit: $vc_file_props(status)"
	    return
	}
    }
    
} else {
    # not using CVS - just write the new content 
    set    ostream [open $content_path w]
    puts  $ostream $content
    close $ostream
}

# if this is a new section which had problems on the upload, we can now
# add it to the database

if { $new == "t"} {
    set new_tcl_list  [split $new_list ","]
    set section_title [lindex $new_tcl_list 0]
    set label         [lindex $new_tcl_list 1]
    set next_sort_key [lindex $new_tcl_list 2]

    db_dml section_insert "
    insert into manual_sections
     ( section_id,
       manual_id,
       section_title,
       label,
       creator_id,
       sort_key,
       content_p)
    values
     (:section_id,
      :manual_id,
      :section_title,
      :label,
      :user_id,
      :next_sort_key,
      't'
    )"
}


ad_returnredirect "section-edit.tcl?[export_url_vars manual_id section_id]"











