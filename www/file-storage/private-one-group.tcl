# /file-storage/private-one-group.tcl

ad_page_contract {
    This file shows the private group tree.
 
    @author randyg@arsdigita.com
    @creation-date January, 2000
    @cvs-id private-one-group.tcl,v 3.12.2.4 2000/09/22 01:37:48 kevin Exp
} {
    {group_id:integer}
}

set return_url "private-one-group?[ns_conn query]"

set user_id [ad_maybe_redirect_for_registration]

if [empty_string_p $group_id] {
    ad_return_complaint 1 "<li>Please choose a group" 
    return
}

if { ![ad_user_group_member $group_id $user_id] } {
    ad_return_error "Unauthorized" "You're not a member of this group"
    return
}

set current_group_id $group_id
set current_group_name [db_string unused "select group_name from user_groups where group_id=:group_id"]

set title "$current_group_name's group document tree"

set page_content  "

<script runat=client>
function launch_window(file) {
    window.open(file,'files','toolbar=no,location=no,directories=no,status=no,scrollbars=auto,resizable=yes,copyhistory=no,width=450,height=250')
}
</script>

[ad_header $title]

<h2> $title </h2>

[ad_context_bar_ws [list "" [ad_parameter SystemName fs]] "One Group"]

<hr align=left>

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
           n_bytes,
           to_char ( fsvl.creation_date, '[fs_date_picture]' ) as creation_date,
	   nvl ( fsvl.file_type, upper ( fsvl.file_extension ) || ' File' ) as file_type,
           fsf.owner_id,
           u.first_names || ' ' || u.last_name as owner_name,
           fsf.sort_key,
           fsvl.version_id,
           fsvl.client_file_name, 
           fsvl.url
    from   fs_files fsf,
           fs_versions_latest fsvl,
           users u
    where  fsf.file_id = fsvl.file_id
    and    fsf.owner_id = u.user_id
    and    deleted_p = 'f'
    and    fsf.group_id = :group_id
    and    (ad_general_permissions.user_has_row_permission_p (:user_id, 'read', fsvl.version_id, 'FS_VERSIONS') = 't' or fsf.owner_id = :user_id)
    order by fsf.sort_key"
            
set file_html ""
set file_count 0

set font "<nobr>[ad_parameter FileInfoDisplayFontTag fs]"
set header_color [ad_parameter HeaderColor fs]

append page_content "
<li>
[fs_folder_box $user_id [fs_private_group_option [list $current_group_id $current_group_name]]]
</li>
"

append page_content "
<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
<tr>
<td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
[fs_header_row_for_files -title "$current_group_name's group document tree" -author_p 1]
" 

db_foreach file_list $sorted_query {
    append file_html [fs_row_for_one_file -n_pixels_in $n_pixels_in \
	    -file_id $file_id \
	    -folder_p $folder_p -client_file_name $client_file_name \
	    -n_kbytes $n_kbytes -n_bytes $n_bytes -file_title $file_title -url $url -creation_date $creation_date \
	    -version_id $version_id -file_type $file_type \
	    -owner_id $owner_id -owner_name $owner_name -author_p 1 \
	    -export_url_vars "[export_url_vars file_id group_id]&source=private_group"]
    
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
</td></tr></table></td></tr></table>

</blockquote>

This system lets you keep your files on [ad_parameter SystemName],
access them from any computer connected to the internet, and
collaborate with others on file creation and modification.

[ad_footer [fs_system_owner]]"

# release the database handle

db_release_unused_handles 

# serve the page

doc_return  200 text/html $page_content 
