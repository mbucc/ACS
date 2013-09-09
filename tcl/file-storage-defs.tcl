# file-storage-defs.tcl

ad_library {
    procedures for the file storage system (user-uploaded file tree)
    documented at /doc/file-storage.html

    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs-id file-storage-defs.tcl,v 3.30.2.6 2000/09/14 07:36:30 ron Exp
}

# modified January, 2000 by randyg@arsdigita.com
# (altered the permissions to now use the general-permissions module)
# permissions are on a per version basis.  Versions inherit the permissions
# from the previous version
 
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


proc_doc fs_order_files {{user_id ""} {group_id ""} {public_p ""}} {Set the ordering and depth for the files so that they may be displayed quickly} {
    # Note: The following query must not use any WHERE clause.
    # Otherwise, Oracle will change the ordering.

    set ordering_query "select file_id, the_level from fs_files_tree"

    set order_depth_list [db_list_of_lists order_info_get $ordering_query]
    set sort_key 1
    
    foreach id_depth $order_depth_list {
	set id [lindex $id_depth 0] 
	set depth [expr [lindex $id_depth 1]-1] 
	db_dml update_ordering "update fs_files set sort_key = :sort_key, 
	                                            depth = :depth 
	                        where file_id = :id"
	incr sort_key
    }
}
 
proc_doc fs_check_edit_p {user_id version_id {group_id ""}} {Returns 1 if the user has permission to edit the version of the file; 0 otherwise} {

    return [fs_check_write_p $user_id $version_id $group_id]

}

proc_doc fs_check_read_p {user_id version_id {group_id ""}} {Returns 1 if the user can read the version of the file; 0 otherwise.} {
    # see if the user is the owner.  If not, see if the user has permission
    if {[db_string read_permission_check "select count(fs_files.file_id) 
                                          from fs_files, fs_versions_latest 
                                          where fs_files.file_id = fs_versions_latest.file_id 
                                          and fs_files.owner_id = :user_id and version_id = :version_id"] > 0} {
	return 1
    } else {
	return [ad_user_has_permission_p $user_id "read" $version_id "FS_VERSIONS"]
    }
}

proc_doc fs_check_write_p {user_id version_id {group_id ""}} {Returns 1 if the user can write the file; 0 otherwise.} {
    set file_id [db_string file_id_get \
        "select file_id 
         from fs_versions_latest 
         where version_id = :version_id"]

    # see if the user is the owner.  If not, see if the user has permission
    if { [db_string permission_check \
            "select count(*) from fs_files 
             where fs_files.file_id = :file_id 
	     and fs_files.owner_id = :user_id"] > 0} {

        return 1

    } else {
        db_1row unused \
            "select folder_p, group_id from fs_files 
             where fs_files.file_id = :file_id"

        if { $folder_p == "t" && ![empty_string_p $group_id] } {
            # Folders in group document trees are a special case: 
            # The user may write to it iff he is a member 
            # of the group.

            return [ad_user_group_member $group_id $user_id]
        }

        return [ad_user_has_row_permission_p $user_id "write" $version_id "FS_VERSIONS"]
    }
}

proc_doc fs_folder_selection {user_id {group_id ""}  {public_p ""} {file_id ""}} {Write out th\e SELECT box that allows the user to move a file to another folder} {
    fs_folder_def_selection $user_id $group_id $public_p $file_id
}


proc_doc fs_folder_def_selection {user_id {group_id ""}  {public_p ""} {file_id ""} {folder_default ""}} {
    Write out the SELECT box that allows the user to move a file to
    another folder, or - if folder_default is provided - create a new
    folder.
} {

    # Get the current location of the file (ie parent_id).
    if {![empty_string_p $file_id]} {
	set current_parent_id [db_string parent_get "select parent_id from fs_files where file_id=:file_id"]
	
	# We don't want to display any folders which are children
	# of the selected file, so use this clause to block them.
	set children_clause "and fs_files_tree.file_id not in (select file_id
	from fs_files
        where file_id != :file_id
	connect by prior file_id = parent_id
	start with file_id = :file_id)"
    } else {
	set current_parent_id ""
	set children_clause ""
    }

    if { [info exists group_id] && ![empty_string_p $group_id] && $public_p != "t"} {    

	set sql_query "select file_title as folder, fs_files_tree.file_id as new_parent, lpad('x',the_level,'x') as spaces
	from   fs_files_tree
	where  folder_p='t'
        and    (public_p <> 't' or public_p is null) 
        and    group_id = :group_id
	and    deleted_p = 'f' 
	$children_clause"

	set group_name [db_string group_name_get "select group_name from user_groups where group_id=:group_id"]
	set top_level "$group_name group tree"

    } elseif {[info exists public_p] && $public_p == "t"}  {

	set sql_query "select file_title as folder, fs_files_tree.file_id as new_parent, lpad('x',the_level,'x') as spaces
	from   fs_files_tree
	where folder_p='t'
	and owner_id = :user_id
        and public_p = 't' 
        and group_id is null
	and deleted_p = 'f' 
	$children_clause"

	set top_level "Shared user tree"
    } else {

	set sql_query "select file_title as folder, fs_files_tree.file_id as new_parent, lpad('x',the_level,'x') as spaces
	from   fs_files_tree
	where folder_p='t'
	and owner_id = :user_id
        and public_p = 'f' 
        and group_id is null
	and deleted_p = 'f' 
	$children_clause"

	set top_level "Private user tree"

    }
    
    if {[empty_string_p $current_parent_id] && [empty_string_p $folder_default]} {
	set file_options "<option value=\"\" selected> $top_level </option>\n"
    } else {
	set file_options "<option value=\"\" > $top_level </option>\n"
    }
    set folder_count 0
    db_foreach file_list $sql_query {
	regsub -all x $spaces {\&nbsp;\&nbsp;} spaces

	incr folder_count
	if  { $current_parent_id == $new_parent && [empty_string_p $folder_default]} {
	    append file_options "<option value=$new_parent selected>$spaces $folder</option>\n"
	} elseif { $folder_default == $new_parent } {
	    append file_options "<option value=$new_parent selected>$spaces $folder</option>\n"
	} else {
	    append file_options "<option value=$new_parent >$spaces $folder</option>\n"
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
#
# ...and modified by lars@pinds.com, May 9, 2000
# to allow for better proctizing of display code.

ad_proc fs_header_row_for_files { 
    {
	-title {}
	-author_p 0
    }
} {
    Returns a table header row containing column names appropriate for
    a listing of files alone (i.e., not versions of files).  Name, Size,
    Type, Modified.

    If you set author_p to 1, you'll additionally get an author column.
} {
    set colspan 5
    if { $author_p } {
	incr colspan
    }

    set font "[ad_parameter FileInfoDisplayFontTag fs]"
    set header_color [ad_parameter HeaderColor fs]
    if { ![empty_string_p $title] } {
	append column_name_header_row "<tr><td colspan=$colspan bgcolor=#666666>
              $font &nbsp;<font color=white> $title
              </td>
          </tr>\n"
    }
    append column_name_header_row  "<tr><td bgcolor=$header_color>$font &nbsp;Name</td>
          <td bgcolor=$header_color align=left>$font &nbsp;Action&nbsp;</td>"
    if { $author_p } {
	append column_name_header_row "
          <td bgcolor=$header_color align=left>$font &nbsp;Author&nbsp;</td>"
    }
    append column_name_header_row "
          <td bgcolor=$header_color>$font &nbsp;Size&nbsp;</td>
          <td bgcolor=$header_color>$font &nbsp;Type&nbsp;</td>
          <td bgcolor=$header_color width=40>$font &nbsp;Modified&nbsp;</td>
      </tr>
    "
    return $column_name_header_row
}

ad_proc fs_row_for_one_file {
    {
	-n_pixels_in 0
	-file_id {}
	-folder_p f
	-client_file_name {}
	-n_kbytes {}
	-n_bytes {}
	-file_title {}
	-file_type {}
	-url {}
	-creation_date {}
	-version_id {}

	-links 1

	-author_p 0
	-owner_id 0
	-owner_name {}
	-user_url {/shared/community-member}

	-export_url_vars {}
	-folder_url {one-folder}
	-file_url {one-file}
    }
} { 
    Returns one row of a HTML table displaying all the information about a file.
    Set links to 0 if you want this file to be output without links to manage it 
    (to display the folder you're currently in). 
  <p>   The first bunch of arguments are all standard stuff we want to
    know about the file. The n_pixels_in is the number of pixels you want this line 
    indented.
  <p>   links:  used for one-folder, which likes to show the current folder first, 
    without the hyperlinks. Set this to 0 if you don't want links from an entry 
   (only works for folders).
  <p>   author: If you want the author shown, set author_p
    and provide us with owner_id and owner_name, and you'll get the link. If you 
    want the link to go somewhere different than /shared/community-member, you'll 
    want to set user_url to the page you want to link to (user_id will be appended).
  <p>  export_url_vars: set this to the vars you want exported when a
    file or folder link is clicked. It should be a query string
    fragment. If you're unhappy with the default urls 'one-folder' or
    'one-file' (say, you're implementing admin pages where they're
    named differently), change them here. The export_url_vars will be
    appended.
} {
    set font "<font face=arial,helvetica size=-1>"
    set gifalign "align=middle"
    set header_color [ad_parameter HeaderColor fs]
    regsub " " $creation_date {\&nbsp;} creation_date_html
    regsub " " $file_title {\&nbsp;} file_title_html
  

    if { $n_pixels_in == 0 } {
	set spacer_gif ""
    } else {
	set spacer_gif "<img src=\"/graphics/file-storage/spacer.gif\" width=$n_pixels_in height=1>"
    }

    if {$folder_p=="t"} {
        append file_html "<tr><td valign=top>&nbsp; $spacer_gif $font"
        if {$links} { append file_html "<a href=\"$folder_url?$export_url_vars\">" 	}

        append file_html "<img border=0 src=/graphics/file-storage/ftv2folderopen.gif $gifalign>"
        if {$links} { append file_html "</a><a href=\"$folder_url?$export_url_vars\">" }

        append file_html $file_title_html
        if {$links} { append file_html "</a>" }

        append file_html "</td>
	<td align=left>&nbsp;</td>"
	
	if {$author_p} { append file_html "<td align=left>&nbsp;</td>" }

	append file_html "
	<td align=right>&nbsp;</td>
	<td>$font &nbsp;File Folder&nbsp;</td>
	<td>&nbsp;</td>
	</tr>\n"

    } elseif {[empty_string_p $n_kbytes]} {

        append file_html "
<tr>
  <td valign=top>&nbsp; $spacer_gif $font
  <a href=\"$file_url?$export_url_vars\"><img border=0 
          src=/graphics/file-storage/ftv2doc.gif $gifalign></a><a 
     href=\"$file_url?$export_url_vars\">$file_title_html</a>&nbsp;</td>
  <td align=left>(<a href=\"$url\">go</a>)</td>
"

	if { $author_p } { append file_html "<td align=left>&nbsp;</td>" }

	append file_html "
	<td align=right>&nbsp;</td>
	<td>$font &nbsp;URL&nbsp;</td>
	<td>$font &nbsp;$creation_date_html&nbsp;</td>
	</tr>\n"

    } else {

        regexp {.*\\([^\\]+)} $client_file_name match client_file_name
	regsub -all {[^-_.0-9a-zA-Z]+} $client_file_name "_" pretty_file_name

        append file_html "
<tr>
  <td valign=top>&nbsp; $spacer_gif $font
  <a href=\"$file_url?$export_url_vars\"><img border=0 
           src=/graphics/file-storage/ftv2doc.gif $gifalign></a><a
     href=\"$file_url?$export_url_vars\">$file_title_html</a>&nbsp;</td>
  <td align=left>$font (<a href=\"/file-storage/download?version_id=$version_id\">download</a>)</td>
"

####	<td align=left>$font (<a href=\"download/$version_id/$pretty_file_name\">download</a>)</td>"

	if { $author_p } {
	    append file_html "
	    <td><a href=\"$user_url?user_id=$owner_id\">$owner_name</a>&nbsp;</td>"
	}

	if { $n_kbytes == 0 } {
	    # this could be improved; see ad-monitor-format-kb in
	    # ad-monitoring-defs
	    set size_string "$n_bytes&nbsp;bytes"
	} else {
	    set size_string "$n_kbytes&nbsp;KB"
	}

	append file_html "
	<td align=right>$font &nbsp;$size_string&nbsp;</td>
	<td>$font &nbsp;[fs_pretty_file_type $file_type]&nbsp;</td>
	<td>$font &nbsp;$creation_date_html&nbsp;</td>
	</tr>\n"
    }
    
    return $file_html
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
# lars@pinds.com, May 8, 2000: Updated to accept URLs of the form 
# /file-storage/download/version_id/filename, e.g. /file-storage/download/5622/au100.gif
# Also added content-disposition and content-length headers.
proc fs_file_downloader {conn key} {
    ns_log Notice "fs_file_downloader ns_conn query = [ns_conn query]"

#    ad_page_variables { {version_id ""} }

    set user_id [ad_verify_and_get_user_id]

    ad_maybe_redirect_for_registration

    
    set exception_text ""
    set exception_count 0

    set urlv [ns_conn urlv]
    set urlc [ns_conn urlc]

    # filename is the last part of the string
    set filename [lindex $urlv [expr $urlc - 1]]

    if {![exists_and_not_null version_id]} {
	# Check to see if it's provided as /file-storage/download/123/file.ext
	set version_id [lindex $urlv [expr $urlc - 2]]

	if {[catch {set version_id [validate_integer {version_id} $version_id]} errMsg]} {
	    incr exception_count
	    append exception_text "<li>No file was specified"
	}
    }

    db_1row file_type_and_size "select file_type, n_bytes from fs_versions where version_id = :version_id"

    # Get the document's group ID, and check if the current user
    # is a member of this group. If he is, we use the group ID
    # as a parameter for fs_check_read_p.

    # Note: This only works as long as read permission can only be granted to the group
    # the document is associated with. Other groups the user is a member of are not checked.

    set group_id [db_string group_id_get "
        select group_id from fs_files fsf, fs_versions fsv
        where version_id = :version_id and fsf.file_id = fsv.file_id"]
    if { ![empty_string_p $group_id] && ![ad_user_group_member $group_id $user_id] } { 
	set group_id "" 
    }

    if { ![fs_check_read_p $user_id $version_id $group_id]} {
        incr exception_count
        append exception_text "<li>You can't read this file"
    }

    ## return errors
    if { $exception_count > 0 } {
        ad_return_complaint $exception_count $exception_text
        return filter_return
    }

    # lars@pinds.com: I'm not sure we really want those -- they'll prevent the browser (at least IE)
    # from opening the file in-browser. A feature I always found annoying, but I don't know if
    # the rest of the world agrees.
    #ns_set put [ns_conn outputheaders] Content-disposition "attachment; filename=\"$filename\""
    #ns_set put [ns_conn outputheaders] Content-length $n_bytes

    ReturnHeaders $file_type

    db_write_blob version_write "select version_content
                                 from   fs_versions
                                 where  version_id = $version_id"

    return filter_return
}

proc_doc fs_guess_source { public_p owner_id group_id local_user_id } "Given some information about a file, tries to guess in which subtree the file belongs. Mainly used by one-file.tcl." {

    if { $public_p == "f" } {
	if { ![empty_string_p $group_id] } {
	    if { [ad_user_group_member $group_id $local_user_id] } {
		return "private_group"
	    } else {
		return "public_group"
	    }
	} elseif { ![empty_string_p $owner_id] } {
	    if { $owner_id == $local_user_id } {
		return "private_individual"
	    } else {
		return "public_individual"
	    }
	}
    } else {
	return "shared"
    }
}

##################################################################
#
# interface to the ad-new-stuff.tcl system
# by carsten@arsdigita.com, April 2000

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [lsearch -glob $ad_new_stuff_module_list "File Storage*"] == -1 } {
    lappend ad_new_stuff_module_list [list "File Storage" fs_new_stuff]
}

proc fs_new_stuff {since_when only_from_new_users_p purpose } {
    if { $only_from_new_users_p == "t" } {
	set where_clause "and author_id in (select user_id from users_new)"
    } else {
	set where_clause ""
    }

    # Get versions uploaded after the given date.
    # Only show files readable by the current user.

    set local_user_id [ad_get_user_id]

    set query "
	select fsf.file_id, file_title, version_description
	from fs_files fsf, fs_versions_latest fsvl
	where creation_date > :since_when
	and fsvl.file_id = fsf.file_id
	and folder_p = 'f'
	and deleted_p = 'f'
	and ad_general_permissions.user_has_row_permission_p (:local_user_id, 'read', version_id, 'FS_VERSIONS' ) = 't'
	$where_clause
	order by creation_date desc"

    set result_items ""
    db_foreach unused $query {
	switch $purpose {
	    web_display {
		append result_items "<li><a href=\"/file-storage/one-file?file_id=$file_id\">$file_title</a><br>\n$version_description\n"
	    }
	    site_admin { 
		append result_items "<li><a href=\"/admin/file-storage/info?file_id=$file_id\">$file_title</a><br>\n$version_description\n"
	    }
	    email_summary {
		append result_items "$file_title"

		if { ![empty_string_p $version_description] } {
		    append result_items " : $version_description"
		}

		append result_items "\n  -- [ad_url]/file-storage/one-file?file_id=$file_id"
            }
	}
    }

    if { $purpose == "email_summary" } {
	return $result_items
    } else {
	set tentative_result $result_items
    }

    # now let's move into the comments on fs territory (we don't do
    # this in a separate new-stuff proc because we want to keep it 
    # together with the new files)
    if { $purpose == "site_admin" } {
	set where_clause_for_approval ""
    } else {
	set where_clause_for_approval "and gc.approved_p = 't'"
    }

    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }

    set comment_query "
	select 
	gc.comment_id, 
	gc.on_which_table, 
	gc.html_p as comment_html_p,
	dbms_lob.substr(gc.content,100,1) as content_intro, 
	gc.on_what_id,
        users.user_id as comment_user_id, 
	gc.comment_date,
	first_names || ' ' || last_name as commenter_name, 
	gc.approved_p,
	file_title, 
	fsf.file_id 
	from general_comments gc, $users_table users, 
	fs_files fsf, fs_versions_latest fsvl
	where users.user_id = gc.user_id 
	and gc.on_which_table = 'fs_files'
	and gc.on_what_id = fsf.file_id
	and fsf.file_id = fsvl.file_id
	and fsf.deleted_p = 'f'
	and ad_general_permissions.user_has_row_permission_p ($local_user_id, 'read', version_id, 'FS_VERSIONS' ) = 't'
	and comment_date > :since_when
	$where_clause_for_approval
	order by gc.comment_date desc"
    
    set result_items ""
    db_foreach comments $comment_query {
	switch $purpose {
	    web_display {
		append result_items "<li>comment from <a href=\"/shared/community-member?user_id=$comment_user_id\">$commenter_name</a> on <a href=\"/file-storage/one-file?file_id=$file_id\">$file_title</a>:
<blockquote>
$content_intro ...
</blockquote>
"
            }
	    site_admin { 
		append result_items "<li>comment from <a href=\"/users/one?user_id=$comment_user_id\">$commenter_name</a> on <a href=\"/admin/file-storage/info?file_id=$file_id\">$title</a>:
<blockquote>
$content_intro ...
</blockquote>
"
	    }
	}
    }

    if { ![empty_string_p $result_items] } {
	append tentative_result \
	    "<h4>comments on files</h4>\n$result_items"
    }

    if { ![empty_string_p $tentative_result] } {
	return "<ul>$tentative_result</ul>"
    } else {
	return ""
    }
}

##################################################################
#
# interface to the ad-user-contributions-summary.tcl system

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "File Storage" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "File Storage" fs_user_contributions 0]
}

proc_doc fs_user_contributions {user_id purpose} {For site admin only, returns statistics and a link to a details page} {
    if { $purpose != "site_admin" } {
	return [list]
    }

    if { [db_0or1row contributions "
	select count(distinct fs_files.file_id) as n_files,
	       round(sum(fs_versions.n_bytes)/1024) as n_kbytes,
	       sum(fs_versions.n_bytes) as n_bytes,
	       max(creation_date) as latest_date
	       from fs_files, fs_versions
	where fs_files.owner_id = :user_id
	and fs_files.file_id = fs_versions.file_id
        and fs_files.deleted_p='f'"]==0 } {
	    return [list]
    }

    if { $n_files == 0 }  {
	return [list]
    } else {
	if { $n_kbytes == 0 } {
	    set size_string "$n_bytes&nbsp;bytes"
	} else {
	    set size_string "$n_kbytes&nbsp;KB"
	}
	return [list 0 "File Storage" "<ul><li><a href=\"/admin/file-storage/personal-space?owner_id=$user_id\">$n_files files</a>
($size_string; latest on [util_AnsiDatetoPrettyDate $latest_date])
</ul>\n"]
    }
}

# --------------------------------------------------------------------------------
# Functions for the document tree select box
#
# Author: Mark Dettinger <dettinger@arsdigita.com>
# Date  : 2000-04-13
#
# uses ad-functional.tcl
# --------------------------------------------------------------------------------

# The document tree select box displays 6 types of links:
#
# 1.  the currently selected tree
# 2.  your personal document tree
# 3a. other group trees
# 3b. other private group trees
# 4.  other personal trees
# 5.  the shared document tree
# 6.  all publically accessible files

# First, define small functions that return these folders neatly wrapped in option tags.

proc fs_private_individual_option {} {
    return "<option value=\"private_individual\">Your personal document tree</option>"
}

proc fs_public_individual_option {user} {
    return "<option value=\"user_id [fst $user]\">
            [snd $user]'s document tree</option>"
}

proc fs_private_group_option {group} {
    return "<option value=\"[list private_group [fst $group]]\">
            [snd $group] group document tree</option>"
}

proc fs_public_group_option {group} {
    return "<option value=\"[list public_group [fst $group]]\">
            [snd $group] group public document tree</option>"
}

proc fs_public_option {} {
    return "<option value=\"all_public\">All publically accessible files</option>"
}

proc fs_shared_option {} {
    if [ad_parameter PublicDocumentTreeP fs] {
	return "<option value=public_tree>[ad_system_name] shared document tree</option>"
    } else {
	return ""
    }
}

# Now, get group folders.

proc fs_groups_where_user_is_member {user_id} {
    db_list_of_lists group_list "
      select user_groups.group_id, group_name
      from   user_groups
      where  ad_group_member_p ( :user_id, user_groups.group_id ) = 't'"
}

proc fs_group_folders {user_id} {
    set group_id_name_list [fs_groups_where_user_is_member $user_id]
    set group_id_list [map fst $group_id_name_list]
    set tags [map fs_private_group_option $group_id_name_list]

    # now, we want to get a list of folders containing files that the user can see
    # but are stored in a directory to which the user does not normally have access

    if {[llength $group_id_list] > 0} {
	set group_clause "and ug.group_id not in ([join $group_id_list ","])"
    } else {
	set group_clause ""
    }

    set group_query "
    select unique ug.group_id,
                  ug.group_name
    from   user_groups ug, 
           fs_files fsf,
           fs_versions_latest fsvl
    where  fsf.file_id = fsvl.file_id
    and    fsf.group_id = ug.group_id
    and    fsf.public_p = 't'
    and    fsf.deleted_p = 'f'
    $group_clause"

    concat $tags [map fs_public_group_option [db_list_of_lists unused $group_query]]
}

# Get private folders.

proc fs_private_folders {user_id} {
    set user_query "
    select unique u.user_id as folder_user_id, 
           u.first_names || ' ' || u.last_name as user_name
    from   users u,
           fs_files fsf,
           fs_versions_latest fsvl
    where  fsf.file_id = fsvl.file_id
    and    not fsf.owner_id = $user_id
    and    fsf.owner_id = u.user_id
    and    fsf.group_id is null
    and    (fsf.public_p = 'f' or fsf.public_p is null)
    and    ad_general_permissions.user_has_row_permission_p ($user_id, 'read', fsvl.version_id, 'FS_VERSIONS') = 't'"

    map fs_public_individual_option [db_list_of_lists unused $user_query]
}

# Create the folder box.

proc_doc fs_folder_box {user_id topmost_option} "Returns the folder box.
Arguments: user_id         the user who is logged in
           topmost_option  the option that should occur on top" {
    set options [nub [concat [list $topmost_option [fs_private_individual_option]] \
			  [ad_decode [fs_shared_option] "" [list] [list [fs_shared_option]]] \
			  [list [fs_public_option]] \
			  [fs_group_folders $user_id] \
			  [fs_private_folders $user_id]]]
    return "
    <form action=group>
    [ad_parameter FileInfoDisplayFontTag fs] 
    Go to 
    <select name=group_id>

    [join $options \n]

    </select> 
    <input type=submit value=go>
    </form>"
}
