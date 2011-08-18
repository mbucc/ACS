# file-storage-defs.tcl
#
# by aure@arsdigita.com, July 1999
# 
# procedures for the file storage system (user-uploaded file tree)
# documented at /doc/file-storage.html

# modifeid January, 2000 by randyg@arsdigita.com
# (altered the permissions to now use the general-permissions module)
# permissions are on a per version basis.  Versions inherit the permissions
# from the previous version
#
# $Id: file-storage-defs.tcl,v 3.5.2.6 2000/03/22 08:59:26 carsten Exp $

util_report_library_entry

proc get_cookie_set {} {
    # by dvr

    set cookie_string [ns_set get [ns_conn headers] Cookie]

    set cookies [ns_set new]

    foreach cookiepairs [split $cookie_string \;] {
        set cookie_list [split $cookiepairs =]
        ns_set put $cookies [string trim [lindex $cookie_list 0]] [string trim [lindex $cookie_list 1]]
    }
    return $cookies
}

proc fs_system_owner {} {
    return [ad_parameter SystemOwner fs [ad_system_owner]]
}



proc_doc fs_date_picture {} "Returns date picture to use with Oracle's TO_CHAR function.  Pulls it from ad.ini parameters file." {
    return [ad_parameter DatePicture fs "YYYY-MM-DD HH24:MI"]
}


proc_doc fs_order_files {db {user_id ""} {group_id ""} {public_p ""}} {Set the ordering and depth for the files so that they may be displayed quickly} {
    # Note: The following query must not use any WHERE clause.
    # Otherwise, Oracle will change the ordering.

    set ordering_query "select file_id, the_level from fs_files_tree"

    set order_depth_list [database_to_tcl_list_list $db $ordering_query]
    set sort_key 1
    
    foreach id_depth $order_depth_list {
	set id [lindex $id_depth 0] 
	set depth [expr [lindex $id_depth 1]-1] 
	ns_db dml $db "update fs_files set sort_key=$sort_key, depth=$depth where file_id=$id"
	incr sort_key
    }
}
 
proc_doc fs_check_edit_p {db user_id version_id {group_id ""}} {Returns 1 if the user has permission to edit the version of the file; 0 otherwise} {

    return [fs_check_write_p $db $user_id $version_id $group_id]

}


proc_doc fs_check_read_p {db user_id version_id {group_id ""}} {Returns 1 if the user can read the version of the file; 0 otherwise.} {
    # see if the user is the owner.  If not, see if the user has permission
    if {[database_to_tcl_string $db "select count(fs_files.file_id) from fs_files, fs_versions_latest where fs_files.file_id = fs_versions_latest.file_id and fs_files.owner_id = $user_id and version_id = $version_id"] > 0} {
	return 1
    } else {
	return [ad_user_has_row_permission_p $db $user_id "read" $version_id "FS_VERSIONS"]
    }
}



proc_doc fs_check_write_p {db user_id version_id {group_id ""}} {Returns 1 if the user can write the file; 0 otherwise.} {
    # see if the user is the owner.  If not, see if the user has permission
    if {[database_to_tcl_string $db "select count(fs_files.file_id) from fs_files, fs_versions_latest where fs_files.file_id = fs_versions_latest.file_id and fs_files.owner_id = $user_id and version_id = $version_id"] > 0} {
	return 1
    } else {
	return [ad_user_has_row_permission_p $db $user_id "write" $version_id "FS_VERSIONS"]
    }
}


proc_doc fs_folder_selection {db user_id {group_id ""}  {public_p ""} {file_id ""}} {Write out th\e SELECT box that allows the user to move a file to another folder} {
    fs_folder_def_selection $db $user_id $group_id $public_p $file_id
}

proc_doc fs_folder_def_selection {db user_id {group_id ""}  {public_p ""} {file_id ""} {folder_default ""}} {Write out the SELECT box that allows the user to move a file to another folder, or - if folder_default is provided - create a new folder.} {

    # Get the current location of the file (ie parent_id).
    if {![empty_string_p $file_id]} {
	set current_parent_id [database_to_tcl_string $db "select parent_id from fs_files where file_id=$file_id"]
	
	# We don't want to display any folders which are children
	# of the selected file, so use this clause to block them.
	set children_clause "and fs_files_tree.file_id not in (select file_id
	from fs_files
	connect by prior file_id = parent_id
	start with file_id = $file_id)"
    } else {
	set current_parent_id ""
	set children_clause ""
    }

    if { [info exists group_id] && ![empty_string_p $group_id] && $public_p != "t"} {    

	set sql_query "select file_title as folder, fs_files_tree.file_id as new_parent, lpad('x',the_level,'x') as spaces
	from   fs_files_tree
	where  folder_p='t'
        and    (public_p <> 't' or public_p is null) 
        and    group_id = $group_id
	and    deleted_p = 'f' $children_clause"

	set group_name [database_to_tcl_string $db "select group_name from user_groups where group_id=$group_id"]
	set top_level "$group_name group tree"

    } elseif {[info exists public_p] && $public_p == "t"}  {

	set sql_query "select file_title as folder, fs_files_tree.file_id as new_parent, lpad('x',the_level,'x') as spaces
	from   fs_files_tree
	where folder_p='t'
	and owner_id=$user_id
        and public_p = 't' 
        and group_id is null
	and deleted_p = 'f' $children_clause"

	set top_level "Shared user tree"

    } else {

	set sql_query "select file_title as folder, fs_files_tree.file_id as new_parent, lpad('x',the_level,'x') as spaces
	from   fs_files_tree
	where folder_p='t'
	and owner_id=$user_id
        and public_p = 'f' 
        and group_id is null
	and deleted_p = 'f' $children_clause"

	set top_level "Private user tree"

    }
    
    if {[empty_string_p $current_parent_id] && [empty_string_p $folder_default]} {
	set file_options "<option value=\"\" selected> $top_level </option>\n"
    } else {
	set file_options "<option value=\"\" > $top_level </option>\n"
    }
    set folder_count 0
    set selection [ns_db select $db $sql_query]
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	
	regsub -all x $spaces {\&nbsp; \&nbsp;} spaces
	if  {$file_id != $new_parent} {
	    incr folder_count
	    if  { $current_parent_id == $new_parent || $folder_default == $new_parent } {
		append file_options "<option value=$new_parent selected>$spaces $folder</option>\n"
	    } else {
		append file_options "<option value=$new_parent >$spaces $folder</option>\n"
	    }
	}
    }


    if { $folder_count > 8 } { 
	set size_count 8
    } else {
	set size_count [expr $folder_count +1]
    }
    set file_options_list "
    <select size=$size_count name=parent_id>
    $file_options
    </select>
    "

    return $file_options_list
}


# simple stupid stuff to help display 
# (all by philg@mit.edu)

proc_doc fs_header_row_for_files {} {Returns a table header row containing column names appropriate for a listing of files alone (i.e., not versions of files).  Name, Size, Type, Modified.} {
    set font "<nobr>[ad_parameter FileInfoDisplayFontTag fs]"
    set header_color [ad_parameter HeaderColor fs]
    set column_name_header_row  "<tr><td bgcolor=$header_color>$font &nbsp; Name</td>
          <td bgcolor=$header_color align=right>$font &nbsp; Size &nbsp;</td>
          <td bgcolor=$header_color>$font &nbsp; Type &nbsp;</td>
          <td bgcolor=$header_color>$font &nbsp; Modified &nbsp;</td>
      </tr>
    "
    return $column_name_header_row
}

proc_doc fs_pretty_file_type {mime_type} {Takes a MIME type and returns a string to be displayed for that type.} {
    return [util_memoize "fs_pretty_file_type_internal {$mime_type}"]
}

proc fs_pretty_file_type_internal {mime_type} {
    # Get the whole fs config section as an ns_set.
    set fs_config_options [ad_parameter_section fs]

    # Loop through the options, picking out any FileTypeMap options.
    set n_config_options [ns_set size $fs_config_options]

    for { set i 0 } { $i < $n_config_options } { incr i } {
	set option [ns_set key $fs_config_options $i]
	if { $option == "FileTypeMap" } {
	    set map_list [split [ns_set value $fs_config_options $i] "|"]

	    # First element is the string to display. The rest
	    # are patterns to check our MIME type against.
	    set display_type [lindex $map_list 0]
	    set patterns [lrange $map_list 1 end]
	    foreach pattern $patterns {
		if { [string match $pattern $mime_type] } {
		    return $display_type
		}
	    }
	}
    }

    # Okay, no pre-configured types. If type is "application/*",
    # return the subtype; else return the primary type.
    set type_list [split $mime_type "/"]
    set main_type [lindex $type_list 0]
    set sub_type [lindex $type_list 1]
    
    if { $main_type == "application" } {
	return [capitalize $sub_type]
    } else {
	return [capitalize $main_type]
    }
}

# filter to preserve file pathname  extension to client browser
ns_share -init {set ad_file_download_filters_installed 0} ad_file_download_filters_installed

if {!$ad_file_download_filters_installed} {
    set ad_file_download_filters_installed 1
    ad_register_filter preauth GET /file-storage/download/* fs_file_downloader
    ad_register_filter preauth GET /admin/file-storage/download/* fs_file_downloader
}

# downloads a file, pulling the filename out of the URL path, to
# preserve file extension for the browser
proc fs_file_downloader {conn key} {
    ns_log Notice "fs_file_downloader ns_conn query = [ns_conn query]"
    set_the_usual_form_variables

    # version_id

    set user_id [ad_verify_and_get_user_id]

    ad_maybe_redirect_for_registration

    set db [ns_db gethandle]
    set exception_text ""
    set exception_count 0

    if {(![info exists version_id])||([empty_string_p $version_id])} {
        incr exception_count
        append exception_text "<li>No file was specified"
    }

    set file_type [database_to_tcl_string $db "select file_type from fs_versions where version_id = $version_id"]


    # Get the document's group ID, and check if the current user
    # is a member of this group. If he is, we use the group ID
    # as a parameter for fs_check_read_p.

    # Note: This only works as long as read permission can only be granted to the group
    # the document is associated with. Other groups the user is a member of are not checked.

    set group_id [database_to_tcl_string $db "
        select group_id from fs_files fsf, fs_versions fsv
        where version_id = $version_id and fsf.file_id = fsv.file_id"]
    if { ![empty_string_p $group_id] && ![ad_user_group_member $db $group_id $user_id] } { 
	set group_id "" 
    }

    if { ![fs_check_read_p $db $user_id $version_id $group_id]} {
        incr exception_count
        append exception_text "<li>You can't read this file"
    }

    ## return errors
    if { $exception_count > 0 } {
        ad_return_complaint $exception_count $exception_text
        return filter_return
    }


    ReturnHeaders $file_type

    ns_ora write_blob $db "select version_content
                       from   fs_versions
                       where  version_id=$version_id"

    return filter_return
}


##################################################################
#
# interface to the ad-user-contributions-summary.tcl system

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "File Storage" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "File Storage" fs_user_contributions 0]
}

proc_doc fs_user_contributions {db user_id purpose} {For site admin only, returns statistics and a link to a details page} {
    if { $purpose != "site_admin" } {
	return [list]
    }
    set selection [ns_db 0or1row $db "select 
  count(distinct fs_files.file_id) as n_files,
  round(sum(fs_versions.n_bytes)/1024) as n_kbytes,
  max(creation_date) as latest_date
from fs_files, fs_versions
where fs_files.owner_id = $user_id
and fs_files.file_id = fs_versions.file_id
and fs_files.deleted_p='f'"]
    if [empty_string_p $selection] {
	return [list]
    }
    set_variables_after_query
    if { $n_files == 0 }  {
	return [list]
    } else {
	return [list 0 "File Storage" "<ul><li><a href=\"/admin/file-storage/personal-space?owner_id=$user_id\">$n_files files</a>
($n_kbytes KB; latest on [util_AnsiDatetoPrettyDate $latest_date])
</ul>\n"]
    }
}

util_report_successful_library_load
