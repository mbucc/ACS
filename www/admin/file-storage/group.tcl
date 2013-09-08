# /admin/file-storage/group.tcl

ad_page_contract {
    Displays a group's files.
    
    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs-id group.tcl,v 3.4.2.4 2000/09/22 01:35:14 kevin Exp
} {
    group_id:integer
}

if [empty_string_p $group_id] {
    ad_return_error "Can't find group" "Can't find group #$group_id"
    return
}

set group_name [db_string group_name_get "
                select group_name from user_groups where group_id = :group_id" -default ""]

if [empty_string_p $group_name] {
    ad_return_error "Can't find group" "Can't find group #$group_id"
    return
}

set return_url "group?[ns_conn query]"
set title "$group_name's files"

set page_content "
[ad_admin_header $title]

<h2> $title </h2>

[ad_admin_context_bar  [list "" [ad_parameter SystemName fs]] $title]

<hr>"

# get the user's files from the database and parse the output to reflect the folder stucture

set sorted_query "
    select fs_files.file_id, 
           file_title, 
           folder_p, 
           depth * 24 as n_pixels_in, 
           to_char(v.creation_date,'[fs_date_picture]') as creation_date,
           round(n_bytes/1024) as n_kbytes, 
           nvl(file_type,upper(file_extension)||' File') as file_type,
           first_names||' '||last_name as owner_name, 
           fs_files.deleted_p, 
           owner_id,
           v.client_file_name, 
           v.url,
           v.version_id
    from   fs_files, 
           fs_versions_latest v, 
           users
    where  group_id = :group_id
    and    owner_id = users.user_id
    and    fs_files.file_id = v.file_id(+)
    order by sort_key"

set file_html ""
set file_count 0

set font "<nobr><font face=arial,helvetica size=-1>"
set header_color "#cccccc"

append page_content "
<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
<tr>
<td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
    [fs_header_row_for_files -title "$group_name's files" -author_p 1]
" 

db_foreach file_list $sorted_query {
    append file_html [fs_row_for_one_file -n_pixels_in $n_pixels_in \
	    -file_id $file_id \
	    -folder_p $folder_p -client_file_name $client_file_name \
	    -n_kbytes $n_kbytes -file_title $file_title -url $url -creation_date $creation_date \
	    -version_id $version_id -file_type $file_type -author_p 1 \
	    -owner_id $owner_id -owner_name $owner_name \
	    -export_url_vars [export_url_vars file_id group_id return_url] \
	    -folder_url {info} -file_url {info} -user_url {/admin/users/one} ]
    
    incr file_count
}

if {$file_count!=0} {

    append page_content $file_html

} else {

    append page_content "<tr><td>&nbsp; No files available in this group. &nbsp;</td></tr>"

}

append page_content "
</td></tr></table></td></tr></table>

</blockquote>

</form>
[ad_admin_footer]"

# release the database handle

db_release_unused_handles 

# serve the page

doc_return  200 text/html $page_content 

