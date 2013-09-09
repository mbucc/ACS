# /tcl/download-defs.tcl

ad_library {
    download module private tcl

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Jan 5 2000
    @cvs-id download-defs.tcl,v 3.26.2.5 2000/07/22 00:01:40 kevin Exp
}

# -----------------------------------------------------------------------------

# This will register the procedure download_serve to serve all
# requested files starting with /download/files

ad_register_proc GET  /download/files/* download_serve
ad_register_proc POST /download/files/* download_serve

ad_proc download_serve { conn context } {
    
    Serve file requests for the download module

} {
    # Need to get possible form variables for the log

    ad_page_contract {} {
	new_log_id:integer,optional
	download_reasons:nohtml,optional
    }

    set url_stub [ns_conn url]

    # This regexp will try to match our filename based on the convention
    # /download/files/<version_id>/<pseudo_filename>
    # <version_id> ::= <integer>
    # <integer>    ::= <integer><digit> | <digit>
    # <digit>      ::= 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
    # <pseudoname> ::= <char>+

    if {[regexp {/download/files/([0-9]+)/(.*)} $url_stub match version_id pseudo_filename]} {
	# we have a valid match
	
	download_version_authorize $version_id

	# This query will extract the directory name from the database
	# where the requested file is kept.
	db_1row directory_from_version "
	select directory_name as directory, 
	       scope as file_scope, 
	       group_id as gid, 
	       download_id as did
	from   downloads
	where  download_id = (select download_id 
                              from   download_versions
	                      where  version_id = :version_id)"

    } elseif { [regexp {/download/files/(.+)/(.+)} $url_stub match directory pseudo_filename] } {
	# we have a valid match, but no version ID. serve the latest file with that
	# directory and pseudo-filename

	if {![db_0or1row directory_from_directory "
        select * from (
	    select d.directory_name as directory, 
	           d.scope as file_scope, 
	           d.group_id as gid, 
	           d.download_id as did,
                   v.version_id
	    from   downloads d, download_versions v
	    where  d.directory_name = :directory
            and    d.download_id = v.download_id
            and    v.pseudo_filename = :pseudo_filename
            order by v.release_date desc, v.version desc
        ) where rownum = 1"]} {

	    ns_returnnotfound
	    return
	}

        download_version_authorize $version_id
    } else {
	# regexp didn't match => not a valid filename
	# Since we can't do anything useful here, let's just
	# throw an error for fun
	ad_return_error "Invalid Filename" "The filename requested does not exist."
	# And log the error also
	ns_log Error "/tcl/download-defs.tcl: Function download_serve failed to map the url to a valid filename"
	return
    }
	

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
	# download_authorize $did
	set full_filename "[ad_parameter DownloadRoot download]groups/$gid/$directory/$version_id.file"
    }

    # Now we need to log who downloaded what
    # First, we need to get the user_id
    set user_id [ad_verify_and_get_user_id]
    
    set new_user_id [ad_decode $user_id 0 "" $user_id]
    
    # This line will return the file with its guessed mimetype

    ns_log Notice "FILE TYPE: [ns_guesstype $pseudo_filename]"
    ns_log Notice "FULL FILENAME: $full_filename"
    ad_returnfile 200 [ns_guesstype $pseudo_filename] $full_filename
    
    # And now, we need to get the IP address of the user
    set user_ip [ns_conn peeraddr]
    
    
    if { ![info exists new_log_id] } {
	# Probably a robot, so no log ID from the previous form. Set one.
	set new_log_id [db_string next_log_id "
	select download_log_id_sequence.nextval from dual"]
    }
    if { ![info exists download_reasons] } {
	# Same deal - probably a robot
	set download_reasons "No reason given (user agent [ns_set iget [ns_conn headers] user-agent])"
    }

    if { [db_string dbl_click_check "select count(*) 
    from download_log where log_id = :new_log_id" ] == 0 } {
	# user did not double click
	# so update the log table by inserting the log entry for
	# this particular download.    
	
	if [catch {db_dml log_insert "
	insert into download_log 
	(log_id, version_id, user_id, entry_date, ip_address, download_reasons)
	values 
	(:new_log_id, :version_id, :new_user_id, sysdate, :user_ip, 
	 :download_reasons)"} errmsg] {
	    # the entry is already in the log - so do nothing
	    ns_log Error "download_log insert choked:  $errmsg"
	}   
    }
    
    # And finally, we're done with the database (duh)
    db_release_unused_handles
}

proc_doc download_admin_authorize { download_id } "given
download_id, this procedure will check whether the user has
administration rights over this download. if download doesn't exist
page is served to the user informing him that the download doesn't
exist. if successfull it will return user_id of the administrator." { 

    if { ![db_0or1row group_for_one_download "
    select scope, group_id, download_id
    from downloads
    where download_id=:download_id"]} {

	uplevel {
	    doc_return  200 text/html "
	    [ad_scope_admin_header "Download Doesn't Exist"]
	    [ad_scope_admin_page_title "Download Doesn't Exist"]
	    [ad_scope_admin_context_bar "No Download"]
	    <hr>
	    <blockquote>
	    Requested download does not exist.
	    </blockquote>
	    [ad_scope_admin_footer]
	    "
	}
	ad_script_abort
    }
 
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }

    set authorization_status [ad_scope_authorization_status $scope admin group_admin none $id]

    set user_id [ad_verify_and_get_user_id]

    switch $authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    ad_script_abort
	}
	reg_required {
	    ad_redirect_for_registration
	    ad_script_abort
	}
    }
}

ad_proc -deprecated download_authorize {
    download_id 
} {
    given download_id,
    this procedure will check whether the user has display rights over
    this download. if download doesn't exist page is served to the user
    informing him that the download doesn't exist. if successfull it will
    return user_id of the administrator.
} { 

    if {![db_0or1row info_for_one_download "
    select scope, group_id, download_id
    from downloads
    where download_id=:download_id"] } {

	uplevel {
	    doc_return  200 text/html "
	    [ad_scope_admin_header "Download Doesn't Exist"]
	    [ad_scope_admin_page_title "Download Doesn't Exist"]
	    [ad_scope_admin_context_bar "No Download"]
	    <hr>
	    <blockquote>
	    Requested download does not exist.
	    </blockquote>
	    [ad_scope_admin_footer]
	    "
	}
	ad_script_abort
    }
 
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }

    set authorization_status [ad_scope_authorization_status $scope registered group_member none $id]

    set user_id [ad_verify_and_get_user_id]

    switch $authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    ad_script_abort
	}
	reg_required {
	    ad_redirect_for_registration
	    ad_script_abort
	}
    }
}

proc_doc download_version_admin_authorize { version_id } "given
version_id, this procedure will check whether the user has
administration rights over this download. if download doesn't exist
page is served to the user informing him that the download doesn't
exist. if successfull it will return user_id of administrator." { 

    if { ![db_0or1row download_id_for_version "
    select download_id
    from download_versions
    where version_id = :version_id "] } {

	ad_scope_return_complaint 1 "Download Version Doesn't Exist"
	ad_script_abort
    }
    
    return [download_admin_authorize $download_id]
    
}

proc_doc download_version_authorize { version_id } "given
version_id, this procedure will check whether the user has visibility
rights over this download. if download doesn't exist page is served to
the user informing him that the download doesn't exist. if successfull
it will return user_id of the user" { 

    if { ![db_0or1row download_id_for_version "
    select download_id
    from download_versions
    where version_id = :version_id "] } {

	ad_scope_return_complaint 1 "Download Version Doesn't Exist"
	ad_script_abort
    }
 
    set user_id [ad_verify_and_get_user_id]

    set user_authorization_status [db_string user_status "
    select download_authorized_p(:version_id, :user_id) from dual"]

    switch $user_authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    ad_script_abort
	}
	reg_required {
	    ad_redirect_for_registration
	    ad_script_abort
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

proc download_version_delete {version_id} {

    download_version_admin_authorize $version_id

    if { ![db_0or1row download_id_for_version "
    select download_id, 
           pseudo_filename
    from   download_versions
    where  version_id = :version_id "] } {

	ad_scope_return_complaint 1 "Download version doesn't exist" 
	ad_script_abort
    }

    db_1row name_for_download "
    select directory_name, 
           scope as file_scope, 
           group_id as gid
    from   downloads 
    where  download_id = :download_id"
    
    if {$file_scope == "public"} {
	set full_filename  "[ad_parameter DownloadRoot download]$directory_name/$version_id.file"
	set notes_filename "[ad_parameter DownloadRoot download]$directory_name/$version_id.notes"
    } else {
	# scope is group
	# download_authorize $did
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
	<blockquote>$errmsg</blockquote>"
	return
    } else {
	
	eval $file_delete_command $notes_filename
	
	db_transaction {
	    db_dml log_delete "
	    delete from download_log	     
	    where version_id = :version_id" 
	    db_dml rules_delete "
	    delete from download_rules    
	    where version_id = :version_id" 
	    db_dml version_delete "
	    delete from download_versions 
	    where version_id = :version_id" 
	}
    }
}

proc_doc download_date_form_check { form date_name } "checks that date_name is a valid date. Returns a list of date_name exception_count, exception_text. Sets date_name to a YYYY-MM-DD format." {

    ns_set update $form "$date_name.day" [string trimleft [ns_set get $form $date_name.day] "0"]

    # check that either all elements are blank or date is formated 
    # correctly for ns_dbformvalue
    if { [empty_string_p [ns_set get $form $date_name.day]] && 
    [empty_string_p [ns_set get $form $date_name.year]] && 
    [empty_string_p [ns_set get $form $date_name.month]] } {
	return [list "" 0 ""]
    } elseif { [catch  { ns_dbformvalue $form $date_name date $date_name} errmsg ] } {
	return [list "" 1 "<li>The date or time was specified in the wrong format.  The date should be in the format Month DD YYYY.\n"]
    } elseif { ![empty_string_p [ns_set get $form $date_name.year]] && [string length [ns_set get $form $date_name.year]] != 4 } {
	return [list "" 1 "<li>The year needs to contain 4 digits.\n"]
    }
    return [list [set $date_name] 0 ""]
}

##################################################################
#
# interface to the ad-new-stuff.tcl system

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [lsearch -glob $ad_new_stuff_module_list "downloads*"] == -1 } {
    lappend ad_new_stuff_module_list [list "Downloads" downloads_new_stuff]
}

proc im_downloads_status {{coverage ""} {report_date ""} {purpose ""} } {
    if { [empty_string_p $coverage] } {
	set coverage 1
    } 
    if { [empty_string_p $report_date] } {
	set report_date sysdate
    } 

    set since_when [db_string date \
	    "select to_date(:report_date, 'YYYY-MM-DD') - :coverage from dual"]
    return [downloads_new_stuff $since_when "f" $purpose]
}

proc downloads_new_stuff {since_when only_from_new_users_p purpose} {
    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }

    set return_list [list]
    
    db_foreach download_list "
    select distinct download_id, download_name
    from downloads" {
    
	set counter [db_string num_downloads "
	select count(*)
	from   download_versions dv, download_log dl, $users_table
	where  dl.version_id  = dv.version_id
	and    dv.download_id = :download_id
	and    dl.entry_date > :since_when
	and    dl.user_id = $users_table.user_id"]
	
	if { $counter > 0 } {
	    
	    if {$purpose == "web_display"} {
		lappend return_list "<a href=\"/download/admin/ad-new-stuff-report?[export_url_vars download_id since_when users_table]\">$download_name</a> ( $counter new downloads )"   
	    } else {
		lappend return_list "$download_name ( $counter new downloads )"
	    }	    
	}
    }
    
    if {[llength $return_list] == 0} {
	return "None \n"
    }
    
    if {$purpose == "web_display"} {
	return "<ul><li>[join $return_list "<li>"]</ul>"
    } else {
	return "[join $return_list "\n"]"
    }

}
