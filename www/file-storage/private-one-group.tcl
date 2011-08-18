# /file-storage/private-one-group.tcl
#
# by randyg@arsdigita.com, January, 2000
#
# This file shows files that belong to groups to users that are not in the
# group but have permission to see the file
#
# $Id: private-one-group.tcl,v 3.3.2.3 2000/03/27 12:57:44 carsten Exp $

ad_page_variables {
    {group_id}
}

set return_url "private-one-group?[ns_conn query]"

set db [ns_db gethandle]

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

if { [ad_user_group_member $db $group_id $user_id] } {
    ns_returnredirect "group?group_id=$group_id"
    return
}

set current_group_id $group_id
set current_group_name [database_to_tcl_string $db "
    select group_name 
    from   user_groups 
    where  group_id=$group_id"]

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

<blockquote>"

# get the group's files from the database and parse the output 
# to reflect the folder stucture

# walk the tree from all nodes with permissions up to the root.
# we do this walk so that we can show all of the folders leading
# up to the files that the user has permission to see


set backwards_tree_walk "
select file_id,	
       file_title,
       sort_key,
       depth,   
       folder_p,
       owner_id,
       deleted_p,
       group_id,
       public_p,
       parent_id,
       level as the_level
from   fs_files
connect by fs_files.file_id = prior parent_id
start with fs_files.file_id in (
    select distinct fs_files.file_id from fs_files, 
           fs_versions_latest
    where  (fs_files.public_p <> 't' or fs_files.public_p is null)
    and    fs_files.group_id = $group_id
    and    folder_p = 'f'
    and    fs_files.deleted_p='f'            
    and    fs_files.file_id=fs_versions_latest.file_id
    and    ad_general_permissions.user_has_row_permission_p ($user_id, 'read', fs_versions_latest.version_id, 'FS_VERSIONS') = 't')"

set sorted_query "
    select distinct desired_files.file_id, 
           desired_files.sort_key,
           file_title, 
           folder_p, 
           depth * 24 as n_pixels_in, 
           to_char(fs_versions_latest.creation_date,'[fs_date_picture]') as creation_date,
           round(n_bytes/1024) as n_kbytes, 
           nvl(file_type,upper(file_extension)||' File') as file_type,
           first_names||' '||last_name as owner_name
    from   ($backwards_tree_walk) desired_files, 
           fs_versions_latest,
           users
    where  fs_versions_latest.file_id = desired_files.file_id
    and    desired_files.owner_id = users.user_id
    order by desired_files.sort_key"

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
    <td colspan=5 bgcolor=#666666> $font &nbsp;<font color=white> 
     $current_group_name's files</td>
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
	 <a href=\"one-folder?[export_url_vars file_id group_id]&source=group\">
	 $file_title</a></td>
	<td align=right></td>
	<td>&nbsp</td>
	<td>$font &nbsp; File Folder &nbsp;</td>
	<td>&nbsp;</td>
	</tr>\n"    

    } else {

	append file_html "
	<tr>
	<td valign=top>&nbsp; $spacer_gif $font
	 <a href=\"one-file?[export_url_vars file_id group_id]&source=group\">
	 <img \n border=0 src=/graphics/file-storage/ftv2doc.gif align=top></a>
	 <a href=\"one-file?[export_url_vars file_id group_id]&source=group\">
	 $file_title</a>&nbsp;</td>
	<td>$font <a href=/shared/community-member?[export_url_vars user_id]>$owner_name</a>&nbsp;</td>
	<td align=right>$font &nbsp; $n_kbytes KB &nbsp;</td>
	<td>$font &nbsp; $file_type &nbsp;</td>
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
        <td>&nbsp; No files available in this group. &nbsp;</td>
        </tr>"
}

append page_content "<tr><td colspan=5 bgcolor=#bbbbbb align=right>"

set group_count 0
set group_query "
    select user_groups.group_id as member_group_id, 
           group_name
    from   user_groups, user_group_map
    where  user_id=$user_id
    and    user_groups.group_id=user_group_map.group_id
    and    user_groups.group_id <> $group_id
    order by group_name"

set selection [ns_db select $db $group_query]

set group_id_list [list]
set group_html ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append group_html "<option value=$member_group_id> 
        $group_name group document tree</option>\n"
    incr group_count
    lappend group_id_list $member_group_id
}


# now, we want to get a list of folders containing files that the user can see
# but are stored in a directory to which the user does not normally have access

# first, get group folders

if {[llength $group_id_list] > 0} {
    set group_clause "and user_groups.group_id not in ([join $group_id_list ","])"
} else {
    set group_clause ""
}

set group_query "
    select user_groups.group_id, 
           group_name 
    from   user_groups, 
           fs_files,
           fs_versions_latest ver
    where  ver.file_id = fs_files.file_id
    and    fs_files.group_id = user_groups.group_id
    and    ad_general_permissions.user_has_row_permission_p ( $user_id, 'read', ver.version_id, 'FS_VERSIONS' ) = 't'
    and    not user_groups.group_id = $group_id
    $group_clause
    group by user_groups.group_id, group_name
    order by group_name"

set selection [ns_db select $db $group_query]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append group_html "<option value=\"[list private_group $group_id]\"> 
        $group_name group document tree</option>\n"
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
    and    ad_general_permissions.user_has_row_permission_p ( $user_id, 'read', ver.version_id, 'FS_VERSIONS' ) = 't'
    and    (fs_files.public_p <> 't' or fs_files.public_p is null)
    group by users.user_id, first_names, last_name
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
        Shared [ad_system_name] document tree"
}

append page_content  "
<form action=group>
<nobr>$font Go to  

<select name=group_id>

<option value=\"private_group $current_group_id\">$current_group_name group document tree</option>
$public_html
$group_html
<option value=\"all_public\">All publically accessible files</option>

</select>

<input type=submit value=go></td></tr> 

</table></td></tr></table></blockquote>

</form>

This system lets you keep your files on [ad_parameter SystemName],
access them from any computer connected to the internet, and
collaborate with others on file creation and modification.

[ad_footer [fs_system_owner]]"

# release the database handle

ns_db releasehandle $db 

# serve the page

ns_return 200 text/html $page_content 

