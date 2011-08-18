# /file-storage/public-one-group.tcl
#
# by philg@mit.edu on July 24, 1999
# 
# show the public files owned by a group
#
# modified by randyg@arsdigita.com, January, 2000 to use the general 
# permissions system
#
# $Id: public-one-group.tcl,v 3.4.2.2 2000/04/28 15:28:33 carsten Exp $

ad_page_variables {
    {group_id ""}
}

set return_url "public-one-group?[ns_conn query]"

set db [ns_db gethandle]

set local_user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

if { ![info exists group_id] || [empty_string_p $group_id] } {
    ad_return_complaint 1 "<li>Please choose a group" 
    return
}

set group_name [database_to_tcl_string $db "
    select group_name from user_groups where group_id=$group_id"]

set title "$group_name's public files"

set page_content  "[ad_header $title]

<h2> $title </h2>

[ad_context_bar_ws [list "" [ad_parameter SystemName fs]]\
	           [list "all-public" "Publically accessible files"]\
		   "One Group"]

<hr>

<blockquote>"

# get the user's files from the database and parse the 
# output to reflect the folder stucture


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
    select distinct fs_files.file_id 
    from   fs_files, 
           fs_versions_latest ver
    where  fs_files.public_p = 'f'
    and    fs_files.group_id = $group_id
    and    folder_p = 'f'
    and    fs_files.deleted_p='f'            
    and    fs_files.file_id=ver.file_id
    and    ad_general_permissions.user_has_row_permission_p ($local_user_id, 'read', ver.version_id, 'FS_VERSIONS') = 't')"

set sorted_query "
    select distinct desired_files.file_id, 
           desired_files.sort_key,
           file_title, 
           folder_p, 
           depth * 24 as n_pixels_in, 
           to_char(fs_versions_latest.creation_date,'[fs_date_picture]') as creation_date,
           round(n_bytes/1024) as n_kbytes, 
           nvl(file_type,upper(file_extension)||' File') as file_type,
	   desired_files.owner_id,
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
     $group_name's files</td>
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
	<td valign=top>&nbsp; ${spacer_gif}$font
	<a href=\"one-folder?[export_url_vars file_id group_id]&source=public_group\">
	<img border=0 src=/graphics/file-storage/ftv2folderopen.gif align=top></a>
	<a href=\"one-folder?[export_url_vars file_id group_id]&source=public_group\">$file_title</a></td>
	<td align=right></td>
	<td>&nbsp;</td>
	<td>$font &nbsp; File Folder &nbsp;</td>
	<td>&nbsp;</td>
	</tr>\n"    

    } else {

	append file_html "
	<tr>
	<td valign=top>&nbsp; ${spacer_gif}$font
	<a href=\"one-file?[export_url_vars file_id group_id]&source=public_group\">
	<img \n border=0 src=/graphics/file-storage/ftv2doc.gif align=top></a>
	<a href=\"one-file?[export_url_vars file_id group_id]&source=public_group\">$file_title</a>&nbsp;</td>
	<td>$font [ad_present_user $owner_id $owner_name] &nbsp;</td>
	<td align=right>$font &nbsp; $n_kbytes KB &nbsp;</td>
	<td>$font &nbsp; $file_type &nbsp;</td>
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
        <td>&nbsp; No files available in this group. &nbsp;</td>
        </tr>"
}

append page_content "
</td></tr></table></td></tr></table></blockquote>

</form>

[ad_footer [fs_system_owner]]"

# release the database handle

ns_db releasehandle $db 

# serve the page

ns_return 200 text/html $page_content 

