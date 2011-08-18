# /file-storage/index.tcl
#
# by aure@arsdigita.com, July 1999
# 
# this will show the shared document tree
# public_p = 't' and group_id is null
#
# $Id: index.tcl,v 3.5.2.6 2000/04/28 15:10:28 carsten Exp $

set cookies [get_cookie_set]
set folders_open_p [ns_set get $cookies folders_open_p]
if [empty_string_p $folders_open_p] {
    set folders_open_p 1
}

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set return_url ""

if ![ad_parameter PublicDocumentTreeP fs] {
    # we are not maintaining a public site wide tree
    ad_returnredirect "personal"
    return
}

if ![info exists folders_open_p] {
    set folders_open_p 1
}

set db [ns_db gethandle]

set title "Shared [ad_system_name] document tree"
set public_p "t"

set page_content  "
[ad_header $title]

<h2> $title </h2>

[ad_context_bar_ws [ad_parameter SystemName fs]]

<hr>

<ul>
<li><a href=upload-new?[export_url_vars return_url public_p]>
    Add a URL / Upload a file</a>
<li><a href=create-folder?[export_url_vars return_url public_p]>
    Create New Folder</a> 

<form action=search method=get>"


# Display search field 

if { [ad_parameter UseIntermediaP fs 0] } {
    append page_content "<li> Search file names and contents for: "
} else {
    append page_content "<li> Search file names for: "
}

append page_content "<input name=search_text type=text size=20>[export_form_vars return_url] <input type=submit value=Search> </form>
</ul>

<blockquote>"



# get the user's files from the database and parse the 
# output to reflect the folder stucture

if {! $folders_open_p} {
   set depth_restriction "\n and depth < 1\n"
} else {
   set depth_restriction ""
}


# a file is considered public if the public_p flag is 't' and
# there are not any entries for the file in the psermissions_ug_map

# fetch all files readable by this user
set sorted_query "
    select fsf.file_id,
           fsf.file_title,
           fsvl.url,
           fsf.folder_p,
           fsf.depth * 24 as n_pixels_in,
           round ( fsvl.n_bytes / 1024 ) as n_kbytes,
           to_char ( fsvl.creation_date, '[fs_date_picture]' ) as creation_date,
           nvl ( fsvl.file_type, upper ( fsvl.file_extension ) || ' File' ) as file_type,
           fsf.sort_key
    from   fs_files fsf,
           fs_versions_latest fsvl
    where  fsf.public_p = 't'
    and    fsf.file_id = fsvl.file_id
    and    (ad_general_permissions.user_has_row_permission_p ( $user_id, 'read', fsvl.version_id, 'FS_VERSIONS' ) = 't' or fsf.owner_id = $user_id )
    and    deleted_p = 'f'$depth_restriction
    order by fsf.sort_key"

set file_html ""
set group_id ""
set file_count 0

set selection [ns_db select $db $sorted_query]

set font "<nobr>[ad_parameter FileInfoDisplayFontTag fs]"

set header_color [ad_parameter HeaderColor fs]

# we start with an outer table to get little white lines in 
# between the elements 

append page_content "
<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
 <tr>
 <td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
      <tr>
      <td colspan=4 bgcolor=#666666> $font &nbsp;<font color=white> 
                                     Shared [ad_system_name] document tree</td>
      </tr>
      <tr>
      <td bgcolor=$header_color>$font &nbsp; Name</td>
      <td bgcolor=$header_color align=right>$font &nbsp; Size &nbsp;</td>
      <td bgcolor=$header_color>$font &nbsp; Type &nbsp;</td>
      <td bgcolor=$header_color>$font &nbsp; Modified &nbsp;</td>
      </tr>" 

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $n_pixels_in == 0 } {
	set spacer_gif ""
    } else {
	set spacer_gif "<img src=\"/graphics/file-storage/spacer.gif\" width=$n_pixels_in height=1>"
    }

    if {$folders_open_p} {
        set folder_icon "ftv2folderopen.gif"
    } else {
        set folder_icon "ftv2folderclosed.gif"
    }

    if {$folder_p=="t"} {

	# write a row for a file folder

        append file_html "
	<tr>
	<td valign=top>&nbsp; $spacer_gif $font
	 <a href=\"one-folder?[export_url_vars file_id]\">
	 <img border=0 src=/graphics/file-storage/$folder_icon align=top></a>
	 <a href=\"one-folder?[export_url_vars file_id]\">$file_title</a></td>
	<td align=right></td>
	<td>$font &nbsp; File Folder &nbsp;</td>
	<td></td>
	</tr>\n"

    } elseif ![empty_string_p $url] {
	
	# write a row for a URL

        append file_html "
	<tr>
	<td valign=top>&nbsp; $spacer_gif $font 
	 <a href=\"one-file?[export_url_vars file_id]\">
	 <img border=0 src=/graphics/file-storage/ftv2doc.gif align=top></a>
	 <a href=\"one-file?[export_url_vars file_id]\">$file_title</a>&nbsp;</td>
	<td align=right></td>
	<td>$font &nbsp; URL &nbsp;</td>
	<td>$font &nbsp; $creation_date &nbsp;</td>
	</tr>\n"

    } else {

	# write a row for a file

        append file_html "
	<tr>
	<td valign=top>&nbsp; $spacer_gif $font
	 <a href=\"one-file?[export_url_vars file_id]\">
	 <img border=0 src=/graphics/file-storage/ftv2doc.gif align=top></a>
	 <a href=\"one-file?[export_url_vars file_id]\">$file_title</a>&nbsp;</td>
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
    <td>There are no [ad_system_name] files stored in the database. </td>
    </tr>"

}

# Show the user a pull-down menu of all other available document trees.
# First list groups he is a member of.

append page_content "<tr><td colspan=4 bgcolor=#bbbbbb align=right>"

set group_query "
    select user_groups.group_id, group_name
    from   user_groups
    where  ad_group_member_p ( $user_id, user_groups.group_id ) = 't'
    order by group_name"
set selection [ns_db select $db $group_query]

set group_option_tags ""
set group_id_list [list]

while {[ns_db getrow $db $selection]} {

    set_variables_after_query

    lappend group_id_list $group_id

    append group_option_tags "
    <option value=$group_id> $group_name group document tree</option>\n"

}

# now, we want to get a list of folders containing files that the user can see
# but are stored in a directory to which the user does not normally have access

# do this for group folders first

if {[llength $group_id_list] > 0} {
    set group_clause "\n and ug.group_id not in ([join $group_id_list ","])\n"
} else {
    set group_clause ""
}

set group_query "
    select ug.group_id,
           ug.group_name 
    from   user_groups ug, 
           fs_files fsf,
           fs_versions_latest fsvl
    where  fsf.file_id = fsvl.file_id
    and    ad_general_permissions.user_has_row_permission_p ($user_id, 'read', fsvl.version_id, 'FS_VERSIONS') = 't'
    and    fsf.group_id = ug.group_id $group_clause
    group by ug.group_id, ug.group_name
    order by group_name"

set selection [ns_db select $db $group_query]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append group_option_tags "
        <option value=\"[list public_group $group_id]\">
        $group_name group document tree
        </option>\n"
}


# now, get personal folders

set user_query "
    select users.user_id as folder_user_id,
           first_names||' '||last_name as user_name
    from   users,
           fs_files,
           fs_versions_latest ver
    where  ver.file_id = fs_files.file_id
    and    not fs_files.owner_id = $user_id
    and    fs_files.owner_id = users.user_id
    and    fs_files.group_id is null
    and    folder_p = 'f'
    and    (fs_files.public_p <> 't' or fs_files.public_p is null)
    and    ad_general_permissions.user_has_row_permission_p ($user_id, 'read', ver.version_id, 'FS_VERSIONS') = 't'
    group by users.user_id, first_names, last_name
    order by user_name"

set selection [ns_db select $db $user_query]

while {[ns_db getrow $db $selection]} {

    set_variables_after_query

    append group_option_tags "
        <option value=\"[list user_id $folder_user_id]\">
        $user_name's private document tree
        </option>\n"
}



append page_content  "
<form action=group>
<nobr> $font 
Go to 
<select name=group_id>
<option value=\"public_tree\" selected>$title</option>
<option value=\"personal\">Your personal document tree</option>

$group_option_tags

<option value=\"all_public\">All publically accessible files</option>
</select> 
<input type=submit value=go></td></tr>
</table></td></tr></table></blockquote>
</form>

This system lets you keep your files on [ad_parameter SystemName],
access them from any computer connected to the internet, and
collaborate with others on file creation and modification.

<p>

[ad_footer [fs_system_owner]]"

# release the database handle

ns_db releasehandle $db 

# serve the page

ns_return 200 text/html $page_content 
