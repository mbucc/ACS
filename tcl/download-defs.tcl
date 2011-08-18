# /tcl/download-defs.tcl
#
# Date:     Wed Jan  5 11:32:17 EST 2000
# Location: 42Å∞22'N 71Å∞03'W
# Author:   Usman Y. Mobin (mobin@mit.edu)
# Purpose:  download module private tcl
#
# $Id: download-defs.tcl,v 3.6.2.4 2000/05/22 18:06:23 ron Exp $
# -----------------------------------------------------------------------------

util_report_library_entry

# This will register the procedure download_serve to serve all
# requested files starting with /download/files

ns_register_proc GET  /download/files/* download_serve
ns_register_proc POST /download/files/* download_serve

proc download_serve { conn context } {

    set_the_usual_form_variables 

    set url_stub [ns_conn url]
    # This regexp will try to match our filename based on the convention
    # /download/files/<version_id>/<pseudo_filename>
    # <version_id> ::= <integer>
    # <integer>    ::= <integer><digit> | <digit>
    # <digit>      ::= 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
    # <pseudoname> ::= <char>+

    if {[regexp {/download/files/([0-9]+)/(.*)} $url_stub match version_id pseudo_filename]} {
	# we have a valid match
	
	set db [ns_db gethandle]
	
	download_version_authorize $db $version_id
	
	# This query will extract the directory name from the database
	# where the requested file is kept.
	set selection [ns_db 1row $db "
	select directory_name as directory, 
	       scope as file_scope, 
	       group_id as gid, 
	       download_id as did
	from   downloads
	where  download_id = (select download_id 
                              from   download_versions
	                      where  version_id = $version_id)"]

	set_variables_after_query
	
	if {![info exists directory] || [empty_string_p $directory]} {
	    # if directory is null then the above query gave no results
	    # which implies through a chain of reasoning that $version_id is
	    # not a valid version_id
	    ad_return_error \
		    "Error in obtaining directory" \
		    "There was an error in obtaining the directory name for the requested download"
	    # And we also log the error
	    ns_log Error "/tcl/download.tcl: Function download_serve
	    failed to determine the directory of the requested
	    download." 
	    # And since we have nothing else better to do, we'll return
	    return
	}

	if {$file_scope == "public"} {
	    set full_filename "[ad_parameter DownloadRoot download]$directory/$version_id.file"
	} else {
	    # scope is group
	    # download_authorize $db $did
	    set full_filename "[ad_parameter DownloadRoot download]groups/$gid/$directory/$version_id.file"
	}

	ns_db releasehandle $db

	# Now we need to log who downloaded what
	# First, we need to get the user_id
	set user_id [ad_verify_and_get_user_id]
	
	set new_user_id [ad_decode $user_id 0 "" $user_id]
	
	# This line will return the file with its guessed mimetype

	ns_log Notice "FILE TYPE: [ns_guesstype $pseudo_filename]"
	ns_log Notice "FULL FILENAME: $full_filename"
	ns_returnfile 200 [ns_guesstype $pseudo_filename] $full_filename

	# And now, we need to get the IP address of the user
	set user_ip [ns_conn peeraddr]

	set db [ns_db gethandle]
	
	if { [database_to_tcl_string $db "select count(*) 
	from download_log where log_id = $new_log_id"] == 0 } {
	    # user did not double click
	    # so update the log table by inserting the log entry for
	    # this particular download.    

	    if [catch {ns_db dml $db "
	    insert into download_log 
	    (log_id, version_id, user_id, entry_date, ip_address, download_reasons)
	    values 
	    ($new_log_id, $version_id, '$new_user_id', sysdate, '$user_ip', '$QQdownload_reasons')" } errmsg] {
		# the entry is already in the log - so do nothing
		ns_log Error "download_log insert choked:  $errmsg"
	    }   
	}

	# And finally, we're done with the database (duh)
	ns_db releasehandle $db

	# And we're also done with serving this file.
	return

    } else {
	# regexp didn't match => not a valid filename
	# Since we can't do anything useful here, let's just
	# throw an error for fun
	ad_return_error "Invalid Filename" "The filename requested does not exist."
	# And log the error also
	ns_log Error "/tcl/download-defs.tcl: Function download_serve failed to map the url to a valid filename"
	return
    }

}

proc_doc download_admin_authorize { db download_id } "given
download_id, this procedure will check whether the user has
administration rights over this download. if download doesn't exist
page is served to the user informing him that the download doesn't
exist. if successfull it will return user_id of the administrator." { 

    set selection [ns_db 0or1row $db "
    select scope, group_id, download_id
    from downloads
    where download_id=$download_id"]

    if { [empty_string_p $selection] } {
	uplevel {
	    ns_return 200 text/html "
	    [ad_scope_admin_header "Download Doesn't Exist" $db]
	    [ad_scope_admin_page_title "Download Doesn't Exist" $db]
	    [ad_scope_admin_context_bar "No Download"]
	    <hr>
	    <blockquote>
	    Requested download does not exist.
	    </blockquote>
	    [ad_scope_admin_footer]
	    "
	}
	return -code 
    }
 
    set_variables_after_query
    
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }

    set authorization_status [ad_scope_authorization_status $db $scope admin group_admin none $id]

    set user_id [ad_verify_and_get_user_id]

    switch $authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    return -code 
	}
	reg_required {
	    ad_redirect_for_registration
	    return -code 
	}
    }
}


proc_doc download_authorize { db download_id } "given download_id,
this procedure will check whether the user has display rights over
this download. if download doesn't exist page is served to the user
informing him that the download doesn't exist. if successfull it will
return user_id of the administrator." { 

    # deprecated

    set selection [ns_db 0or1row $db "
    select scope, group_id, download_id
    from downloads
    where download_id=$download_id"]

    if { [empty_string_p $selection] } {
	uplevel {
	    ns_return 200 text/html "
	    [ad_scope_admin_header "Download Doesn't Exist" $db]
	    [ad_scope_admin_page_title "Download Doesn't Exist" $db]
	    [ad_scope_admin_context_bar "No Download"]
	    <hr>
	    <blockquote>
	    Requested download does not exist.
	    </blockquote>
	    [ad_scope_admin_footer]
	    "
	}
	return -code 
    }
 
    set_variables_after_query
    
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }

    set authorization_status [ad_scope_authorization_status $db $scope registered group_member none $id]

    set user_id [ad_verify_and_get_user_id]

    switch $authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    return -code 
	}
	reg_required {
	    ad_redirect_for_registration
	    return -code 
	}
    }
}


proc_doc download_version_admin_authorize { db version_id } "given
version_id, this procedure will check whether the user has
administration rights over this download. if download doesn't exist
page is served to the user informing him that the download doesn't
exist. if successfull it will return user_id of administrator." { 

    set selection [ns_db 0or1row $db "select download_id
    from download_versions
    where version_id = $version_id "]

    if { [empty_string_p $selection] } {
	ad_scope_return_complaint 1 "Download Version Doesn't Exist" $db
	return -code 
    }
 
    set_variables_after_query
    
    return [download_admin_authorize $db $download_id]
    
}

proc_doc download_version_authorize { db version_id } "given
version_id, this procedure will check whether the user has visibility
rights over this download. if download doesn't exist page is served to
the user informing him that the download doesn't exist. if successfull
it will return user_id of the user" { 

    set selection [ns_db 0or1row $db "select download_id
    from download_versions
    where version_id = $version_id "]

    if { [empty_string_p $selection] } {
	ad_scope_return_complaint 1 "Download Version Doesn't Exist" $db
	return -code 
    }
 
    set_variables_after_query
    
    set user_id [ad_verify_and_get_user_id]

    set user_authorization_status [database_to_tcl_string $db "
    select download_authorized_p($version_id, $user_id) from dual"]

    switch $user_authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    return -code 
	}
	reg_required {
	    ad_redirect_for_registration
	    return -code 
	}
    }

}

proc_doc download_mkdir {dirname} "Ensures that \$dirname exists. Won't cause 
an error if the directory is already there. Better than the stardard
mkdir because it will make all the directories leading up to
\$dirname" {  
    set dir_list [split $dirname /]
    set needed_dir ""
    foreach dir $dir_list {
        if [empty_string_p $dir] {
            continue
        }
        append needed_dir "/$dir"
        if ![file exists $needed_dir] {
            ns_mkdir $needed_dir
        }
    }
}

# this procedure deletes the download version file from file storge 
# and related data from the database 

proc download_version_delete {db version_id} {

    download_version_admin_authorize $db $version_id

    set selection [ns_db 0or1row $db "
    select download_id, 
           pseudo_filename
    from   download_versions
    where  version_id = $version_id "]

    if { [empty_string_p $selection] } {
	ad_scope_return_complaint 1 "Download version doesn't exist" $db
	return -code return
    }
 
    set_variables_after_query

    set selection [ns_db 1row $db "
    select directory_name, 
           scope as file_scope, 
           group_id as gid
    from   downloads 
    where  download_id = $download_id"]
    
    set_variables_after_query
    
    if {$file_scope == "public"} {
	set full_filename  "[ad_parameter DownloadRoot download]$directory_name/$version_id.file"
	set notes_filename "[ad_parameter DownloadRoot download]$directory_name/$version_id.notes"
    } else {
	# scope is group
	# download_authorize $db $did
	set full_filename  "[ad_parameter DownloadRoot download]groups/$gid/$directory_name/$version_id.file]"
	set notes_filename "[ad_parameter DownloadRoot download]groups/$gid/$directory_name/$version_id.notes"
    }

    set aol_version [ns_info version]
    
    if { $aol_version < 3.0 } {
	set file_delete_command "exec /bin/rm"  
    } else {
	set file_delete_command "file delete" 
    }
    
    if [catch {eval $file_delete_command $full_filename} errmsg] {
	ad_scope_return_complaint 1 "
	<li>File $full_filename could not be deleted because of the following error:
	<blockquote>$errmsg</blockquote>" $db
	return
    } else {
	
	eval $file_delete_command $notes_filename
	
	ns_db dml $db "begin transaction"
	ns_db dml $db "delete from download_log	     where version_id = $version_id"
	ns_db dml $db "delete from download_rules    where version_id = $version_id"
	ns_db dml $db "delete from download_versions where version_id = $version_id"
	ns_db dml $db "end transaction"
    }
}

proc_doc download_date_form_check { form date_name } "checks that date_name is a valid date. Returns a list of date_name exception_count, exception_text. Sets date_name to a YYYY-MM-DD format." {

    set encoded_date [ns_urlencode $date_name]

    ns_set update $form "ColValue.$encoded_date.day" [string trimleft [ns_set get $form ColValue.$encoded_date.day] "0"]

    # check that either all elements are blank or date is formated 
    # correctly for ns_dbformvalue
    if { [empty_string_p [ns_set get $form ColValue.$encoded_date.day]] && 
    [empty_string_p [ns_set get $form ColValue.$encoded_date.year]] && 
    [empty_string_p [ns_set get $form ColValue.$encoded_date.month]] } {
	return [list "" 0 ""]
    } elseif { [catch  { ns_dbformvalue $form $date_name date $date_name} errmsg ] } {
	return [list "" 1 "<li>The date or time was specified in the wrong format.  The date should be in the format Month DD YYYY.\n"]
    } elseif { ![empty_string_p [ns_set get $form ColValue.$encoded_date.year]] && [string length [ns_set get $form ColValue.$encoded_date.year]] != 4 } {
	return [list "" 1 "<li>The year needs to contain 4 digits.\n"]
    }
    return [list [set $date_name] 0 ""]
}

util_report_successful_library_load
