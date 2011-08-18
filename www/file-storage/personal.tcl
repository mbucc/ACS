# /file-storage/personal.tcl
# 
# by aure@arsdigita.com, July 1999
#
# this file displays all files in the user's personal folder
#
# modified by randyg@arsdigita.com, January, 2000 to use the general 
# permissions module
#
# $Id: personal.tcl,v 3.2.2.5 2000/03/31 16:11:16 carsten Exp $

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set cookies [get_cookie_set]
set folders_open_p [ns_set get $cookies folders_open_p]
if [empty_string_p $folders_open_p] {
    set folders_open_p 1
}

set return_url "personal"

set db [ns_db gethandle]

set name_query "select first_names||' '||last_name as name 
               from   users 
               where  user_id = $user_id"
set name [database_to_tcl_string $db $name_query]

set title "$name's Documents"

set public_p "f"

set page_content  "
[ad_header $title ]

<h2> $title </h2>

[ad_context_bar_ws [list "" [ad_parameter SystemName fs]] "Personal document tree"]

<hr>

<ul>
   <li><a href=upload-new?[export_url_vars return_url public_p]>Add a URL / Upload a new file</a>
   <li><a href=create-folder?[export_url_vars return_url public_p]>Create New Folder</a> (for storing personal files)

   <form action=search method=post>
"

if { [ad_parameter UseIntermediaP fs 0] } {
    append page_content "<li> Search file names and contents for: "
} else {
    append page_content "<li> Search file names for: "
}

append page_content "<input name=search_text type=text size=20>[export_form_vars return_url]<input type=submit value=Search></form>

</ul>
<blockquote>"

# get the user's files from the database and parse the output to 
# reflect the folder stucture

set sorted_query "
    select fsf.file_id,
           fsf.file_title,
           fsvl.url,
           fsf.folder_p,
           fsf.depth * 24 as n_pixels_in,
           round ( fsvl.n_bytes / 1024 ) as n_kbytes,
           to_char ( fsvl.creation_date, '[fs_date_picture]' ) as creation_date,
           nvl ( fsvl.file_type, upper ( fsvl.file_extension ) || ' File' ) as file_type
    from   fs_files fsf,
           fs_versions_latest fsvl
    where  fsf.file_id = fsvl.file_id
    and    deleted_p = 'f'
    and    fsf.owner_id = $user_id
    and    fsf.group_id is null
    and    (fsf.public_p = 'f' or fsf.public_p is null)
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
    <td colspan=4 bgcolor=#666666>
    $font &nbsp;<font color=white> Your personal files</td>
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
    if {$folder_p=="t"} {

	append file_html "
	<tr>
	<td valign=top>&nbsp; $spacer_gif $font
	<a href=\"one-folder?[export_url_vars file_id group_id]&source=personal\">
	<img border=0 src=/graphics/file-storage/ftv2folderopen.gif align=top></a>
	<a href=\"one-folder?[export_url_vars file_id]&source=personal\">$file_title</a></td><td align=right></td>
	<td>$font &nbsp; File Folder &nbsp;</td>
	<td>&nbsp;</td>
	</tr>\n"    

    } else {

	if {![empty_string_p $n_kbytes]} {
	    set n_kbytes "$n_kbytes KB"
	}
	append file_html "
	<tr>
	<td valign=top>&nbsp; $spacer_gif $font
	<a href=\"one-file?[export_url_vars file_id group_id]&source=personal\">
	<img \n border=0 src=/graphics/file-storage/ftv2doc.gif align=top></a>
	<a href=\"one-file?[export_url_vars file_id]&source=personal\">$file_title</a>&nbsp;</td>
	<td align=right>$font &nbsp; $n_kbytes &nbsp;</td>
	<td>$font &nbsp; [fs_pretty_file_type $file_type] &nbsp;</td>
	<td>$font &nbsp; $creation_date &nbsp;</td>
	</tr>\n"    
    }
    
    incr file_count
}

if {$file_count!=0} {
    append page_content $file_html
} else {
    append page_content "
        <tr>
        <td>You don't have any files stored in the database. </td>
        </tr>"
}

append page_content "<tr><td colspan=4 bgcolor=#bbbbbb align=right>"

set group_count 0
set group_query "
    select group_id, 
           group_name
    from   user_groups
    where  ad_group_member_p ($user_id, group_id) = 't'
    order by group_name"

set selection [ns_db select $db $group_query]

set group_html ""
set group_id_list [list]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append group_html "<option value=$group_id> 
        $group_name group document tree</option>\n"
    incr group_count
    lappend group_id_list $group_id
}


# now, we want to get a list of folders containing files that the user can see
# but are stored in a directory to which the user does not normally have access

# first, get group folders

if {[llength $group_id_list] > 0} {
    set group_clause "and ug.group_id not in ([join $group_id_list ","])"
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
    and    fsf.group_id = ug.group_id
    $group_clause
    group by ug.group_id, ug.group_name
    order by group_name"

set selection [ns_db select $db $group_query]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append group_html "<option value=\"[list public_group $group_id]\"> 
        $group_name group document tree</option>\n"
}


# now, get personal folders

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
    and    ad_general_permissions.user_has_row_permission_p ($user_id, 'read', fsvl.version_id, 'FS_VERSIONS') = 't'
    order by user_name"

set selection [ns_db select $db $user_query]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append group_html "<option value=\"[list user_id $folder_user_id]\"> 
        $user_name's private document tree</option>\n"
}



set public_html ""
if [ad_parameter PublicDocumentTreeP fs] {
    set public_html "<option value=public_tree>
        [ad_system_name] shared document tree"
}


append page_content  "
<form action=group>
<nobr>$font Go to  

<select name=group_id>

<option value=personal>Your personal files</option>
$public_html
$group_html
<option value=\"all_public\">All publically accessible files</option>

</select>

<input type=submit value=go>

</td></tr></table></td></tr></table>

</blockquote>

</form>

This system lets you keep your files on [ad_parameter SystemName],
access them from any computer connected to the internet, and
collaborate with others on file creation and modification.

[ad_footer [fs_system_owner]]"

# release the database handle

ns_db releasehandle $db 

# Serve the page.
# Because we are called without parameters, we add a Pragma: no-cache.

ns_set put [ns_conn outputheaders] "Pragma" "no-cache"
ReturnHeaders
ns_write $page_content
