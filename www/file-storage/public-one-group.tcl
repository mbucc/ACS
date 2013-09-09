# /file-storage/public-one-group.tcl

ad_page_contract {
    show the public files owned by a group

    @author philg@mit.edu
    @creation-date July 24, 1999
    @cvs-id public-one-group.tcl,v 3.13.2.4 2000/09/22 01:37:48 kevin Exp

    modified by randyg@arsdigita.com, January, 2000 to use the general 
    permissions system
} {
    {group_id ""}
}

set return_url "public-one-group?[ns_conn query]"

set local_user_id [ad_maybe_redirect_for_registration]

if { ![info exists group_id] || [empty_string_p $group_id] } {
    ad_return_complaint 1 "<li>Please choose a group" 
    return
}

set group_name [db_string unused "
    select group_name from user_groups where group_id=:group_id"]

set title "$group_name's public group document tree"

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
    where  fs_files.public_p = 't'
    and    fs_files.group_id = :group_id
    and    folder_p = 'f'
    and    fs_files.deleted_p='f'            
    and    fs_files.file_id=ver.file_id
    and    ad_general_permissions.user_has_row_permission_p (:local_user_id, 'read', ver.version_id, 'FS_VERSIONS') = 't')"

set sorted_query "
    select distinct desired_files.file_id, 
           desired_files.sort_key,
           file_title, 
           folder_p, 
           depth * 24 as n_pixels_in, 
           to_char(fsvl.creation_date,'[fs_date_picture]') as creation_date,
           round(n_bytes/1024) as n_kbytes,
           n_bytes,
           nvl(file_type,upper(file_extension)||' File') as file_type,
	   desired_files.owner_id,
           first_names||' '||last_name as owner_name,
           fsvl.client_file_name,
           fsvl.url,
           fsvl.version_id
    from   ($backwards_tree_walk) desired_files, 
           fs_versions_latest fsvl,
           users
    where  fsvl.file_id = desired_files.file_id
    and    desired_files.owner_id = users.user_id
    order by desired_files.sort_key"

set file_html ""
set file_count 0

set font "<nobr>[ad_parameter FileInfoDisplayFontTag fs]"
set header_color [ad_parameter HeaderColor fs]

append page_content "
<li>
[fs_folder_box $local_user_id [fs_public_group_option [list $group_id $group_name]]]
</li>
"

append page_content "
<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
<tr>
<td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
[fs_header_row_for_files -title "$group_name's public group document tree" -author_p 1]
" 

db_foreach file_list $sorted_query {
    append file_html [fs_row_for_one_file -n_pixels_in $n_pixels_in \
	    -file_id $file_id \
	    -folder_p $folder_p -client_file_name $client_file_name \
	    -n_kbytes $n_kbytes -n_bytes $n_bytes -file_title $file_title -url $url -creation_date $creation_date \
	    -version_id $version_id -file_type $file_type \
	    -export_url_vars "[export_url_vars file_id group_id]&source=public_group" \
	    -author_p 1 -owner_id $owner_id -owner_name $owner_name]
    
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

[ad_footer [fs_system_owner]]"

# release the database handle

db_release_unused_handles 

# serve the page

doc_return  200 text/html $page_content 

