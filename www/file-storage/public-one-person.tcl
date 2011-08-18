# /file-storage/public-one-person.tcl
#
# by philg@mit.edu July 24, 1999
# 
# list the public files of one user
#
# modified by randyg@arsdigita.com January, 2000 to use the
# general permissions module
#
# $Id: public-one-person.tcl,v 3.3.2.1 2000/04/28 15:10:28 carsten Exp $

ad_page_variables {owner_id}

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set owner_name [database_to_tcl_string $db "
    select first_names || ' ' || last_name from users where user_id = $owner_id"]

set page_content  "[ad_header "Public files owned by $owner_name"]

<h2>$owner_name's Files</h2>

[ad_context_bar_ws [list "" [ad_parameter SystemName fs]] \
	           [list "all-public" "Publically accessible files"]\
		   "One Person's"]

<hr>

<blockquote>"

# get the user's files from the database and parse the output 
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
    select distinct fs_files.file_id 
    from   fs_files, 
           fs_versions_latest ver
    where  owner_id = $owner_id
    and    folder_p = 'f'
    and    fs_files.file_id=ver.file_id
    and    (fs_files.public_p = 'f' or fs_files.public_p is null)
    and    fs_files.group_id is null
    and    (ad_general_permissions.user_has_row_permission_p ($user_id, 'read', ver.version_id, 'FS_VERSIONS') = 't'
    and    fs_files.deleted_p='f'))"

set sorted_query "
select   distinct desired_files.file_id, 
         desired_files.sort_key,
         file_title, 
         folder_p, 
         depth * 24 as n_pixels_in, 
         to_char(fs_versions_latest.creation_date,'[fs_date_picture]') as creation_date,
         round(n_bytes/1024) as n_kbytes, 
         nvl(file_type,upper(file_extension)||' File') as file_type
from     ($backwards_tree_walk) desired_files, 
         fs_versions_latest
where    fs_versions_latest.file_id = desired_files.file_id
order by desired_files.sort_key, desired_files.file_title"

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
    <td colspan=5 bgcolor=#666666>$font &nbsp;<font color=white> $owner_name's public files</td>
    </tr>
    <tr>
    <td bgcolor=$header_color>$font &nbsp; Name</td>
    <td bgcolor=$header_color align=right>$font &nbsp; Size &nbsp;</td>
    <td bgcolor=$header_color>$font &nbsp; Type &nbsp;</td>
    <td bgcolor=$header_color>$font &nbsp; Modified &nbsp;</td>
    </tr>" 

if [empty_string_p $selection] {
    ad_returnredirect ""
    return
}

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
	<a href=one-folder?[export_url_vars file_id owner_id]&source=public_individual>
	<img border=0 src=/graphics/file-storage/ftv2folderopen.gif align=top></a>
	<a href=one-folder?[export_url_vars file_id group_id owner_id]&source=public_individual>$file_title</a></td>
	<td>&nbsp;</td>
	<td>$font &nbsp; File Folder &nbsp;</td>
	<td>&nbsp;</td>
	</tr>\n"    

    } else {

	append file_html "
	<tr>
	<td valign=top>&nbsp; ${spacer_gif}$font
	<a href=one-file?[export_url_vars file_id owner_id]&source=public_individual>
	<img \n border=0 src=/graphics/file-storage/ftv2doc.gif align=top></a>
	<a href=one-file?[export_url_vars file_id owner_id]&source=public_individual>$file_title</a>&nbsp;</td>
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
</td></tr></table></td></tr></table></blockquote>

[ad_footer [fs_system_owner]]"

# release the database handle

ns_db releasehandle $db 

# serve the page

ns_return 200 text/html $page_content 

