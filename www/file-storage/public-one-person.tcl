# /file-storage/public-one-person.tcl
ad_page_contract {
    list the public files of one user

    @author philg@mit.edu
    @creation-date July 24, 1999
    @cvs-id public-one-person.tcl,v 3.12.2.4 2000/09/22 01:37:48 kevin Exp

    modified by randyg@arsdigita.com January, 2000 to use the
    general permissions module
} {
    user_id:integer
}

set local_user_id [ad_maybe_redirect_for_registration]

set owner_id $user_id
set owner_name [db_string unused "
    select first_names || ' ' || last_name from users where user_id = :user_id"]

set page_content  "[ad_header "Public files owned by $owner_name"]

<h2>$owner_name's public document tree</h2>

[ad_context_bar_ws [list "" [ad_parameter SystemName fs]] \
	           [list "all-public" "Publically accessible files"]\
		   "One Person's"]

<hr align=left>

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
    where  owner_id = :user_id
    and    folder_p = 'f'
    and    fs_files.file_id=ver.file_id
    and    fs_files.group_id is null
    and    (fs_files.public_p = 't' or
            ad_general_permissions.user_has_row_permission_p (:local_user_id, 'read', ver.version_id, 'FS_VERSIONS') = 't')
    and    fs_files.deleted_p='f')"

set sorted_query "
select   distinct desired_files.file_id, 
         desired_files.sort_key,
         file_title, 
         folder_p, 
         depth * 24 as n_pixels_in, 
         to_char(fs_versions_latest.creation_date,'[fs_date_picture]') as creation_date,
         round(n_bytes/1024) as n_kbytes,
         n_bytes, 
         nvl(file_type,upper(file_extension)||' File') as file_type,
         client_file_name,
         url,
         version_id
from     ($backwards_tree_walk) desired_files, 
         fs_versions_latest
where    fs_versions_latest.file_id = desired_files.file_id
order by desired_files.sort_key, desired_files.file_title"

set file_html ""
set file_count 0

set font "<nobr><font face=arial,helvetica size=-1>"
set header_color "#cccccc"

append page_content "
<li>
[fs_folder_box $local_user_id [fs_public_individual_option [list $owner_id $owner_name]]]
</li>
"

append page_content "
<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
<tr>
<td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
[fs_header_row_for_files -title "$owner_name's public document tree"]
" 

db_foreach file_list $sorted_query {
    append file_html [fs_row_for_one_file -n_pixels_in $n_pixels_in \
	    -file_id $file_id \
	    -folder_p $folder_p -client_file_name $client_file_name \
	    -n_kbytes $n_kbytes -n_bytes $n_bytes -file_title $file_title -url $url -creation_date $creation_date \
	    -version_id $version_id -file_type $file_type \
	    -export_url_vars "owner_id=$user_id&[export_url_vars file_id]&source=public_individual"]
    
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

# serve the page

doc_return  200 text/html $page_content 

