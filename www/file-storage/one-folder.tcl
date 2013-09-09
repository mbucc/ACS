# /file-storage/one-folder.tcl

ad_page_contract {
    summary of one folder

    @author philg@mit.edu 
    @creation-date July 23 1999 
    @cvs-id one-folder.tcl,v 3.23.2.5 2000/09/22 01:37:48 kevin Exp

    modified by randyg@arsdigita.com January, 2000 to use 
    the general permissions system
} {
    {file_id}
    {group_id ""}
    {source ""}
    {owner_id ""}
}

set return_url "one-folder?[ns_conn query]"

set local_user_id [ad_maybe_redirect_for_registration]

set name_query "select first_names||' '||last_name as name 
                from   users 
                where  user_id = :local_user_id"
set user_name [db_string unused $name_query]

set exception_text ""
set exception_count 0

if [empty_string_p $file_id] {
    incr exception_count
    append exception_text "<li>No folder was specified"
}

set version_id [db_string unused "
    select version_id 
    from   fs_versions_latest 
    where  file_id = :file_id"]

set sql "
    select fsf1.file_title,
           fsf2.file_title as parent_title,
           fsf1.folder_p,
           fsf1.parent_id,
	   fsf1.public_p,
	   fsf1.owner_id,
	   fsf1.group_id,
	   u.first_names || ' ' || u.last_name as owner_name,
           ad_general_permissions.user_has_row_permission_p ( fsf1.owner_id, 'read', fsvl.version_id, 'FS_VERSIONS' ) as public_read_p
    from   fs_files fsf1,
           fs_files fsf2,
           fs_versions_latest fsvl,
           users u
    where  fsf1.file_id = :file_id
    and    fsf1.file_id = fsvl.file_id
    and    fsf1.parent_id = fsf2.file_id (+)
    and    fsf1.owner_id = u.user_id"
 
if { [db_0or1row file_list $sql]==0 } {
    ad_return_error "Folder not found" "Could not find 
        folder $file_id; it may have been deleted."
    return
}

if { $folder_p != "t" } {
    # we got here by mistake, push them out into the right place 
    # (this shouldn't happen!)
    ns_log Error "User was sent to /file-storage/one-file.tcl to view a FILE (#$file_id)"
    ad_returnredirect "one-file?[export_entire_form_as_url_vars]"
    return
}

if { ![fs_check_read_p $local_user_id $version_id $group_id] } {
    ad_return_complaint 1 "<li>You don't have authority to read this folder"
}

set object_type "Folder"

set title $file_title

if { [empty_string_p $parent_title] } {
    set parent_title "Root (Top Level)"
}

if { [empty_string_p $source] } {
    set source [fs_guess_source $public_p $owner_id $group_id $local_user_id]
}

# the navbar is determined by where the just came from

set sql_suffix ""

switch $source {
    "private_individual" {
	set tree_name "Your personal document tree"

	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "private-one-person" $tree_name] "One Folder"]
	set box [fs_folder_box $local_user_id [fs_private_individual_option]]
	set public_p f
}
    "private_group" {
	set group_name [db_string unused "
		select group_name from user_groups where group_id=:group_id" -default ""]
	set tree_name "$group_name group document tree"

	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "private-one-group?[export_url_vars group_id]" $tree_name] "One Folder"]
	set box [fs_folder_box $local_user_id [fs_private_group_option [list $group_id $group_name]]]
	set public_p f
    }
    "public_individual" {
	set tree_name "$owner_name's document tree"

	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "all-public" "Publically accessible files"] [list "public-one-person?user_id=$owner_id" $tree_name] "One Folder"]
	set box [fs_folder_box $local_user_id [fs_public_individual_option [list $owner_id $owner_name]]]
	set public_p t
    }
    "public_group" {
	set group_name [db_string unused "
		select group_name from user_groups where group_id=:group_id" -default ""]
	set tree_name "$group_name group public document tree"

	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "all-public" "Publically accessible files"] [list "public-one-group?[export_url_vars group_id]" $tree_name] "One Folder"]
	set box [fs_folder_box $local_user_id [fs_public_group_option [list $group_id $group_name]]]
	set public_p t
    }
    default {
	set tree_name "Shared [ad_system_name] document tree"
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] "One Folder"]
	set box [fs_folder_box $local_user_id [fs_shared_option]]
	set public_p t
    }
}
 
set page_content  "
[ad_header $title ]

<h2> $title </h2>

$navbar

<hr align=left>
"

## determine if the user owns the folder - user_id is the owner_id?
set action_list [list]

if [fs_check_edit_p $local_user_id $version_id $group_id] {
    # If she owns it, provide links for folder editing, file upload and
    # creation of subfolders.

    set this_folder $file_id
    set url_vars [export_url_vars return_url public_p this_folder group_id]

    lappend action_list "<a href=\"file-edit?[export_url_vars group_id file_id return_url]\">edit</a>" \
    "<a href=upload-new?$url_vars>Add a URL / Upload a file</a>" \
    "<a href=create-folder?$url_vars>Create New Folder</a>"
}

if {[llength $action_list] >0} {
    set actions_option "<p><li>Actions:  [join $action_list " | "]"
} else {
    set actions_option ""
}

append page_content "

<ul>
<li> $object_type Title: $file_title
<li> Owner: $owner_name
<li> Located in: $tree_name / $parent_title

$actions_option

"

set tree_walk "
select file_id,	
       file_title,
       sort_key,
       depth,   
       folder_p,
       owner_id,
       group_id,
       public_p,
       parent_id,
       level as the_level
from   fs_files
where  deleted_p = 'f'
connect by parent_id = prior file_id start with file_id = :file_id
"

# get the files from the database and parse 
# the output to reflect the folder stucture
# Only show files the user has permission to read

set sorted_query "
    select desired.file_id,
           file_title,
           folder_p,
           depth * 24 as n_pixels_in,
           round (fsvl.n_bytes / 1024) as n_kbytes,
           n_bytes,
           to_char (fsvl.creation_date, '[fs_date_picture]') as creation_date,
           nvl (fsvl.file_type, upper (fsvl.file_extension) || ' File') as file_type,
           sort_key,
           fsvl.version_id,
           fsvl.client_file_name,
           fsvl.url
    from   fs_versions_latest fsvl,
	   ($tree_walk) desired
    where  fsvl.file_id = desired.file_id
    and    (ad_general_permissions.user_has_row_permission_p (:local_user_id, 'read', fsvl.version_id, 'FS_VERSIONS') = 't' or owner_id = :local_user_id or folder_p = 't')
    order by sort_key"

set file_html ""
set file_count 0

set font "<nobr><font face=arial,helvetica size=-1>"

set header_color [ad_parameter HeaderColor fs]

append page_content <li>$box</li>

append page_content "
<blockquote>
<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
 <tr>
 <td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
     [fs_header_row_for_files -title "Files in $file_title"]
" 

db_foreach list_of_files $sorted_query {
    # We ignore the first element's indentation and shift all rows left by
    # that many pixels.
    if !$file_count {
	set initial_pixels $n_pixels_in
    }

    append file_html [fs_row_for_one_file -n_pixels_in [expr $n_pixels_in - $initial_pixels] \
	    -file_id $file_id \
	    -folder_p $folder_p -links $file_count -client_file_name $client_file_name \
	    -n_kbytes $n_kbytes -n_bytes $n_bytes -file_title $file_title -url $url -creation_date $creation_date \
	    -version_id $version_id -file_type $file_type \
	    -export_url_vars [export_url_vars file_id group_id owner_id source]]

    incr file_count
}

if {$file_count!=0} {
    append page_content "$file_html"
} else {
    append page_content "
    <tr>
    <td>You don't have any files stored in this folder. </td>
    </tr>"
}

append page_content "
</table></td></tr></table></blockquote>

</ul>

[ad_footer [fs_system_owner]]"

# release the database handle

db_release_unused_handles

# serve the page

doc_return  200 text/html $page_content

