# /file-storage/group.tcl
# 
# by aure@arsdigita.com, June 1999
#
# modified by randyg@arsdigita.com, January 2000
#
# This file displays all group wide files that the user has permission to see
#
# $Id: group.tcl,v 3.2.2.4 2000/04/28 15:10:27 carsten Exp $

ad_page_variables {
    {group_id ""}
}

set local_user_id [ad_get_user_id]

# group_id

if { $group_id == "all_public" } {
    ad_returnredirect "all-public"
    return
}

if { $group_id == "personal" } {
    ad_returnredirect "personal"
    return
}

if { $group_id == "public_tree" } {
    ad_returnredirect ""
    return
}

if { [lindex $group_id 0] == "user_id" } {
    ad_returnredirect "private-one-person?owner_id=[lindex $group_id 1]"
    return
}

if { [lindex $group_id 0] == "private_group" } {
    ad_returnredirect "private-one-group?group_id=[lindex $group_id 1]"
    return
}

if { [lindex $group_id 0] == "public_group" } {
    ad_returnredirect "public-one-group?group_id=[lindex $group_id 1]"
    return
}


set return_url "group?[ns_conn query]"

set db [ns_db gethandle]

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

if [empty_string_p $group_id] {
    ad_return_complaint 1 "<li>Please choose a group" 
    return
}

if { ![ad_user_group_member $db $group_id $user_id] } {
    ad_return_error "Unauthorized" "You're not a member of this group"
    return
}

set current_group_id $group_id
set current_group_name [database_to_tcl_string $db "select group_name from user_groups where group_id=$group_id"]

set title "$current_group_name's document tree"

set page_content  "

<script runat=client>
function launch_window(file) {
    window.open(file,'files','toolbar=no,location=no,directories=no,status=no,scrollbars=auto,resizable=yes,copyhistory=no,width=450,height=250')
}
</script>

[ad_header $title]

<h2> $title </h2>

[ad_context_bar_ws [list "" [ad_parameter SystemName fs]] "One Group"]

<hr>

<ul>
   <li><a href=upload-new?[export_url_vars return_url group_id]>
       Upload a new file</a> to this group
   <li><a href=create-folder?[export_url_vars return_url group_id]>
       Create New Folder</a> (for storing group files)
</ul>

<blockquote>"

# get the group's files from the database and parse the output 
# to reflect the folder stucture

set sorted_query "
    select fsf.file_id,
           fsf.file_title,
           fsf.folder_p,
           fsf.depth * 24 as n_pixels_in,
           round ( fsvl.n_bytes / 1024 ) as n_kbytes,
           to_char ( fsvl.creation_date, '[fs_date_picture]' ) as creation_date,
	   nvl ( fsvl.file_type, upper ( fsvl.file_extension ) || ' File' ) as file_type,
           u.user_id,
           u.first_names || ' ' || u.last_name as owner_name,
           fsf.sort_key
    from   fs_files fsf,
           fs_versions_latest fsvl,
           users u
    where  fsf.file_id = fsvl.file_id
    and    fsf.owner_id = u.user_id
    and    deleted_p = 'f'
    and    fsf.group_id = $group_id
    and    (ad_general_permissions.user_has_row_permission_p ($user_id, 'read', fsvl.version_id, 'FS_VERSIONS') = 't' or fsf.owner_id = $user_id)
    order by fsf.sort_key"
            
set file_html ""
set file_count 0

set selection [ns_db select $db $sorted_query]

set font "<nobr>[ad_parameter FileInfoDisplayFontTag fs]"
set header_color [ad_parameter HeaderColor fs]

append page_content "
<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
<tr>
<td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
    <tr>
    <td colspan=5 bgcolor=#666666>
        $font &nbsp;<font color=white> $current_group_name's files</td>
    </tr>
    <tr>
    <td bgcolor=$header_color>$font &nbsp; Name</td>
    <td bgcolor=$header_color>$font &nbsp; Author &nbsp;</td>
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
	<a href=\"one-folder?[export_url_vars file_id group_id]&source=group\">
	<img border=0 src=/graphics/file-storage/ftv2folderopen.gif align=top></a>
	<a href=\"one-folder?[export_url_vars file_id group_id]&source=group\">$file_title</a></td>
	<td align=right></td>
	<td>&nbsp;</td>
	<td>$font &nbsp; File Folder &nbsp;</td>
	<td>&nbsp;</td>
	</tr>\n"
    
    } else {

	append file_html "
	<tr>
	<td valign=top>&nbsp; $spacer_gif $font
	<a href=\"one-file?[export_url_vars file_id group_id]&source=group\">
	<img \n border=0 src=/graphics/file-storage/ftv2doc.gif align=top></a>
	<a href=\"one-file?[export_url_vars file_id group_id]&source=group\">$file_title</a>&nbsp;</td>
	<td>$font <a href=/shared/community-member?[export_url_vars user_id]>$owner_name</a>&nbsp;</td>
	<td align=right>$font &nbsp; $n_kbytes KB &nbsp;</td>
	<td>$font &nbsp; $file_type &nbsp;</td>
	<td>$font &nbsp; $creation_date &nbsp;</td></tr>\n"

    }
    
    incr file_count
}

if {$file_count!=0} {

    append page_content $file_html

} else {

    append page_content "
    <tr>
    <td>&nbsp; No files available in this group. &nbsp;</td>
    </tr>"

}

append page_content "<tr><td colspan=5 bgcolor=#bbbbbb align=right>"

set group_count 0
set group_query "
    select group_id as member_group_id, 
           group_name
    from   user_groups
    where  ad_group_member_p ( $local_user_id, group_id ) = 't'
    and    group_id <> $current_group_id
    order by group_name"

set selection [ns_db select $db $group_query]

set group_html ""

while {[ns_db getrow $db $selection]} {

    set_variables_after_query

    append group_html "
        <option value=$member_group_id>
        $group_name group document tree</option>\n"

    incr group_count

    lappend group_id_list $member_group_id

}


# now, we want to get a list of folders containing files that the user can see
# but are stored in a directory to which the user does not normally have access

# first, get group folders

set group_query "
    select ug.group_id,
           ug.group_name 
    from   user_groups ug, 
           fs_files fsf,
           fs_versions_latest fsvl
    where  fsf.file_id = fsvl.file_id
    and    fsf.group_id = ug.group_id
    and    ad_group_member_p ( $local_user_id, fsf.group_id ) = 'f'
    group by ug.group_id, ug.group_name
    order by group_name"

set selection [ns_db select $db $group_query]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append group_html "
        <option value=\"[list public_group $group_id]\">
        $group_name group document tree</option>\n"
}

set user_query "
    select unique u.user_id as folder_user_id, 
           u.first_names || ' ' || u.last_name as user_name
    from   users u,
           fs_files fsf,
           fs_versions_latest fsvl
    where  fsf.file_id = fsvl.file_id
    and not fsf.owner_id = $user_id
    and    fsf.owner_id = u.user_id
    and    fsf.group_id is null
    and    (fsf.public_p <> 't' or fsf.public_p is null)
    and    ad_general_permissions.user_has_row_permission_p ($user_id, 'read', fsvl.version_id, 'FS_VERSIONS') = 't'
    order by user_name"

set selection [ns_db select $db $user_query]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append group_html "
        <option value=\"[list user_id $folder_user_id]\"> 
        $user_name's private document tree</option>\n"
}



set public_html ""
if [ad_parameter PublicDocumentTreeP fs] {
    set public_html "<option value=public_tree>[ad_system_name] shared document tree"
}

append page_content  "
<form action=group>
<nobr>$font Go to  
<select name=group_id>

<option value=\"$current_group_id\">$current_group_name group document tree</option>
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

# serve the page

ns_return 200 text/html $page_content 
