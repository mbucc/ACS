# /file-storage/private-one-person.tcl
#
# by randyg@arsdigita.com January, 2000
# 
# list the private files of one user that the logged in user is allowed to view
#
# $Id: private-one-person.tcl,v 3.4.2.3 2000/03/31 16:11:17 carsten Exp $

ad_page_variables {owner_id}

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

if {$owner_id == $user_id} {
    ns_returnredirect "personal"
    return
}

set owner_name [database_to_tcl_string $db "
    select first_names || ' ' || last_name 
    from   users 
    where  user_id = $owner_id"]

set page_content  "[ad_header "Private files owned by $owner_name"]

<h2>$owner_name's Files</h2>

[ad_context_bar_ws [list "" [ad_parameter SystemName fs]] "One Person's Private Files"]

<hr>

<blockquote>"

# get the user's files from the database and parse the output to 
# reflect the folder stucture

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
           fs_versions_latest ver
    where  (fs_files.public_p <> 't' or fs_files.public_p is null)
    and    fs_files.group_id is null
    and    fs_files.owner_id = $owner_id
    and    fs_files.deleted_p='f'            
    and    fs_files.file_id=ver.file_id
    and    ad_general_permissions.user_has_row_permission_p ($user_id, 'read', ver.version_id, 'FS_VERSIONS') = 't')"


set sorted_query "
    select distinct desired_files.file_id, desired_files.sort_key,
           file_title, 
           folder_p, 
           depth * 24 as n_pixels_in, 
           to_char(fs_versions_latest.creation_date,'[fs_date_picture]') as creation_date,
           round(n_bytes/1024) as n_kbytes, 
           nvl(file_type,upper(file_extension)||' File') as file_type
    from   ($backwards_tree_walk) desired_files, 
           fs_versions_latest
    where  fs_versions_latest.file_id = desired_files.file_id
    order by desired_files.sort_key"

set file_html ""
set file_count 0

set selection [ns_db select $db $sorted_query]

set font "<nobr><font face=arial,helvetica size=-1>"
set header_color "#cccccc"

append page_content "
<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
<tr>
<td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
    <tr>
    <td colspan=5 bgcolor=#666666>
     $font &nbsp;<font color=white> $owner_name's private files</td>
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

    if { $folder_p == "t" } {

	append file_html "
	<tr>
	<td>&nbsp; ${spacer_gif}$font
	<a href=one-folder?[export_url_vars file_id owner_id]&source=private_individual>
	<img align=top border=0 src=/graphics/file-storage/ftv2folderopen.gif></a>
	<a href=one-folder?[export_url_vars file_id group_id owner_id]&source=private_individual>$file_title</a></td>
	<td align=right></td>
	<td>&nbsp;</td>
	<td>$font &nbsp; File Folder &nbsp;</td>
	<td>&nbsp;</td>
	</tr>\n"    

    } else {

	append file_html "
	<tr>
	<td>&nbsp; ${spacer_gif}$font
	<a href=one-file?[export_url_vars file_id owner_id]&source=private_individual>
	<img align=top border=0 src=/graphics/file-storage/ftv2doc.gif></a>
	<a href=one-file?[export_url_vars file_id owner_id]&source=private_individual>$file_title</a>&nbsp;</td>
	<td>$font <a href=\"/shared/community-member?user_id=$owner_id\">$owner_name</a>&nbsp;</td>\
	<td align=right>$font &nbsp; $n_kbytes KB &nbsp;</td>
	<td>$font &nbsp; [fs_pretty_file_type $file_type] &nbsp;</td>
	<td>$font &nbsp; $creation_date &nbsp;</td>
	</tr>\n"    

    }
    
    incr file_count
}

if { $file_count != 0 } {
    append page_content $file_html
} else {
    append page_content "
        <tr>
        <td>&nbsp; No files available in this group. &nbsp;</td>
        </tr>"
}

append page_content "
</td></tr>
<tr><td colspan=5 bgcolor=#bbbbbb align=right>"

set group_count 0
set group_query "
    select group_id as member_group_id, 
           group_name  
    from   user_groups
    where  ad_group_member_p ($user_id, group_id) = 't'
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

if { [llength $group_id_list] > 0 } {
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
    $group_clause
    and    ad_general_permissions.user_has_row_permission_p ($user_id, 'read', ver.version_id, 'FS_VERSIONS') = 't'
    group by user_groups.group_id, group_name
    order by group_name"

set selection [ns_db select $db $group_query]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append group_html "<option value=\"[list public_group $group_id]\"> 
        $group_name group document tree</option>\n"
}

# now, get personal folders

set group_query "
    select users.user_id as folder_user_id, 
           first_names||' '||last_name as user_name
    from   users,
           fs_files,
           fs_versions_latest ver
    where  ver.file_id = fs_files.file_id
    and    not fs_files.owner_id = $user_id
    and    fs_files.owner_id = users.user_id
    and    fs_files.group_id is null
    and    users.user_id <> $owner_id
    and    folder_p = 'f'
    and    (fs_files.public_p <> 't' or fs_files.public_p is null)
    and    ad_general_permissions.user_has_row_permission_p ($user_id, 'read', ver.version_id, 'FS_VERSIONS') = 't'
    group by users.user_id, first_names, last_name
    order by user_name"

set selection [ns_db select $db $group_query]

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

<option value=\"user_id $owner_id\">$owner_name's private document tree</option>
$public_html
$group_html
<option value=\"all_public\">All publically accessible files</option>

</select>

<input type=submit value=go>
</td></tr></table></td></tr></table>

</blockquote>

[ad_footer [fs_system_owner]]"

# release the database handle

ns_db releasehandle $db 

# serve the page

ns_return 200 text/html $page_content 

