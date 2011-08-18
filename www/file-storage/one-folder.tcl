# /file-storage/one-folder.tcl
#
# by philg@mit.edu July 23 1999 
#
# summary of one folder
#
# modified by randyg@arsdigita.com January, 2000 to use 
# the general permissions system
#
# one-folder.tcl,v 3.3.2.1 2000/03/15 20:27:58 carsten Exp

ad_page_variables {
    {file_id}
    {group_id ""}
    {source ""}
    {owner_id ""}
}

set return_url "one-folder?[ns_conn query]"

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set exception_text ""
set exception_count 0

if [empty_string_p $file_id] {
    incr exception_count
    append exception_text "<li>No folder was specified"
}

set version_id [database_to_tcl_string $db "
    select version_id 
    from   fs_versions_latest 
    where  file_id = $file_id"]

if { ![fs_check_read_p $db $user_id $version_id $group_id] } {
    incr exception_count
    append exception_text "<li>You don't have authority to read this folder"
}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set selection [ns_db 0or1row $db "
    select fsf1.file_title,
           fsf2.file_title as parent_title,
           fsf1.folder_p,
           fsf1.parent_id,
           u.first_names || ' ' || u.last_name as owner_name,
           ad_general_permissions.user_has_row_permission_p ( fsf1.owner_id, 'read', fsvl.version_id, 'FS_VERSIONS' ) as public_read_p
    from   fs_files fsf1,
           fs_files fsf2,
           fs_versions_latest fsvl,
           users u
    where  fsf1.file_id = $file_id
    and    fsf1.file_id = fsvl.file_id
    and    fsf1.parent_id = fsf2.file_id (+)
    and    fsf1.owner_id = u.user_id"]
 
if [empty_string_p $selection] {
    ad_return_error "Folder not found" "Could not find 
        folder $file_id; it may have been deleted."
    return
}

set_variables_after_query

if { $folder_p != "t" } {
    # we got here by mistake, push them out into the right place 
    # (this shouldn't happen!)
    ns_log Error "User was sent to /file-storage/one-file.tcl to view a FILE (#$file_id)"
    ad_returnredirect "one-file?[export_entire_form_as_url_vars]"
    return
}


set object_type "Folder"

set title $file_title

if { [empty_string_p $parent_title] } {
    set parent_title "Root (Top Level)"
}

if { ![empty_string_p $group_id]} {
    set group_name [database_to_tcl_string $db "
    select group_name 
    from   user_groups 
    where  group_id=$group_id"]

    set tree_name "$group_name document tree"

} else {
    if {$public_read_p == "t"} {
	set tree_name "Shared [ad_system_name] document tree"
    } else {
	set tree_name "Your personal document tree"
    }
}


# the navbar is determined by where the just came from

set sql_suffix ""

switch $source {
    "personal" {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "personal" "Personal Document Tree"] "One File"]
	set sql_suffix "and fsf.public_p = 'f' and fsf.owner_id = $user_id and fsf.group_id is null"
	set public_p f
}
    "group" { 
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "group?group_id=$group_id" "$group_name document tree"] "One File"]
	set sql_suffix "and fsf.group_id = $group_id"
	set public_p t
    }
    "public_individual" {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "public-one-person?[export_url_vars owner_id]" "$owner_name's publically accessible files"] "One File"]
	set sql_suffix "and ad_general_permissions.user_has_row_permission_p ( $owner_id, 'read', fsvl.version_id, 'FS_VERSIONS' ) = 't' and fsf.owner_id = $owner_id and fsf.group_id is null"
	set public_p t
    }
    "public_group" {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "public-one-group?[export_url_vars group_id]" "$group_name publically accessible files"] "One File"]
	set sql_suffix "and ad_general_permissions.user_has_row_permission_p ( $owner_id, 'read', fsvl.version_id, 'FS_VERSIONS' ) = 't' and fsf.group_id = $group_id"
	set public_p t
    }
    "private_individual" {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "private-one-person?[export_url_vars owner_id]" "$owner_name's privately accessible files"] "One File"]
	set sql_suffix "and fsf.owner_id = $owner_id and fsf.public_p = 'f'"
	set public_p f
    }
    "private_group" {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "private-one-group?[export_url_vars group_id]" "$group_name privately accessible files"] "One File"]
	set sql_suffix "and ad_general_permissions.user_has_row_permission_p ( $owner_id, 'read', fsvl.version_id, 'FS_VERSIONS' ) = 'f' and fsf.group_id = $group_id"
	set public_p f
    }
    default {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] "One File"]
	set public_p t
    }
}
 
set page_content  "
[ad_header $title ]

<h2> $title </h2>

$navbar

<hr>
"

## determine if the user owns the folder - user_id is the owner_id?
set action_list [list]


if [fs_check_edit_p $db $user_id $version_id $group_id] {
    # If she owns it, provide links for folder editing, file upload and
    # creation of subfolders.

    set current_folder $file_id
    set url_vars [export_url_vars return_url public_p current_folder group_id]

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

</ul>"

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
connect by parent_id = prior file_id start with file_id = $file_id
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
           to_char (fsvl.creation_date, '[fs_date_picture]') as creation_date,
           nvl (fsvl.file_type, upper (fsvl.file_extension) || ' File') as file_type,
           sort_key
    from   fs_versions_latest fsvl,
	   ($tree_walk) desired
    where  fsvl.file_id = desired.file_id
    and    (ad_general_permissions.user_has_row_permission_p ($user_id, 'read', fsvl.version_id, 'FS_VERSIONS') = 't' or owner_id = $user_id or folder_p = 't')
    order by sort_key"

set file_html ""
set file_count 0

set selection [ns_db select $db $sorted_query]

set font "<nobr><font face=arial,helvetica size=-1>"

set header_color [ad_parameter HeaderColor fs]

append page_content "
<blockquote>
<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
 <tr>
 <td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
     <tr>
     <td colspan=4 bgcolor=#666666>$font &nbsp;<font color=white>files in $file_title</td>
     </tr>
     <tr>
     <td bgcolor=$header_color>$font &nbsp; Name</td>
     <td bgcolor=$header_color align=right>$font &nbsp; Size &nbsp;</td>
     <td bgcolor=$header_color>$font &nbsp; Type &nbsp;</td>
     <td bgcolor=$header_color>$font &nbsp; Modified &nbsp;</td>
     </tr>" 

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    # We ignore the first element's indentation and shift all rows left by
    # that many pixels.
    if !$file_count {
	set initial_pixels $n_pixels_in
    }
    set n_pixels_in [expr $n_pixels_in - $initial_pixels]

     if { $n_pixels_in == 0 } {
	set spacer_gif ""
     } else {
	set spacer_gif "<img src=\"/graphics/file-storage/spacer.gif\" width=$n_pixels_in height=1>"
    }

    set one_file_url "one-file?[export_url_vars file_id group_id owner_id source]"

    if {$folder_p=="t"} {

        append file_html "<tr><td valign=top>&nbsp; $spacer_gif $font"
        if $file_count { append file_html "<a href=\"one-folder?[export_url_vars file_id]\">" }
        append file_html "<img border=0 src=/graphics/file-storage/ftv2folderopen.gif align=top>"
        if $file_count { append file_html "</a> <a href=\"one-folder?[export_url_vars file_id]\">" }
        append file_html $file_title
        if $file_count { append file_html "</a>" }
        append file_html "</td>
	<td align=right>&nbsp;</td>
	<td>$font &nbsp; File Folder &nbsp;</td>
	<td>&nbsp;</td>
	</tr>\n"

    } elseif {[empty_string_p $n_kbytes]} {

        append file_html "
	<tr>
	<td valign=top>&nbsp; $spacer_gif $font
	<a href=\"$one_file_url\">
	<img border=0 src=/graphics/file-storage/ftv2doc.gif align=top></a>
	<a href=\"$one_file_url\">$file_title</a>&nbsp;</td>
	<td align=right>&nbsp;</td>
	<td>$font &nbsp; URL &nbsp;</td>
	<td>$font &nbsp; $creation_date &nbsp;</td>
	</tr>\n"

    } else {

        append file_html "
	<tr>
	<td valign=top>&nbsp; $spacer_gif $font
	<a href=\"$one_file_url\">
	<img border=0 src=/graphics/file-storage/ftv2doc.gif align=top></a>
	<a href=\"$one_file_url\">$file_title</a>&nbsp;</td>
	<td align=right>$font &nbsp; $n_kbytes KB &nbsp;</td>
	<td>$font &nbsp; [fs_pretty_file_type $file_type] &nbsp;</td>
	<td>$font &nbsp; $creation_date &nbsp;</td>
	</tr>\n"

    }

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

ns_db releasehandle $db

# serve the page

ns_return 200 text/html $page_content

