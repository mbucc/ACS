# /admin/file-storage/personal-space.tcl
ad_page_contract {
    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs-id personal-space.tcl,v 3.6.2.5 2000/09/22 01:35:15 kevin Exp
} {
    owner_id:integer
}

set user_id $owner_id
set return_url group?[ns_conn query]

set bind_vars [ad_tcl_vars_to_ns_set user_id]

set sql_query "select first_names||' '||last_name as name 
               from   users 
               where  user_id=:user_id"
set name [db_string unused $sql_query -bind $bind_vars]

set title "$name's Files"
set owner_name $name

set return_url personal-space?[ns_conn query]

set page_content  "[ad_admin_header $title]

<h2> $title </h2>

[ad_admin_context_bar [list "" [ad_parameter SystemName fs]] $title]

<hr>

<blockquote>
"
# get the user's files from the database and parse the output to reflect the folder stucture

set sorted_query "
    select fs_files.file_id, 
           file_title, 
           folder_p, 
           depth * 24 as n_pixels_in, 
           round(fsvl.n_bytes/1024) as n_kbytes,
           n_bytes,
           to_char(fsvl.creation_date,'[fs_date_picture]') as creation_date,
           nvl(file_type,upper(file_extension)||' File') as file_type,
           fsvl.client_file_name, 
           fsvl.url,
           fsvl.version_id
    from   fs_files, fs_versions_latest fsvl
    where  owner_id = :user_id
    and    fs_files.file_id=fsvl.file_id(+)
    and    group_id is NULL
    and    deleted_p='f'
    order by sort_key"

set file_html ""
set file_count 0

set font "<nobr><font face=arial,helvetica size=-1>"
set header_color "#cccccc"

append page_content "
<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
<tr>
<td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
      [fs_header_row_for_files -title "$name's files" -author_p 1]
" 

db_foreach list_of_files $sorted_query -bind $bind_vars {
    append file_html [fs_row_for_one_file -n_pixels_in $n_pixels_in \
	    -file_id $file_id \
	    -folder_p $folder_p -client_file_name $client_file_name \
	    -n_kbytes $n_kbytes -n_bytes $n_bytes -file_title $file_title -url $url -creation_date $creation_date \
	    -version_id $version_id -file_type $file_type -author_p 1 \
	    -owner_id $owner_id -owner_name $owner_name \
	    -export_url_vars [export_url_vars file_id group_id owner_name return_url] \
	    -folder_url {info} -file_url {info} -user_url {/admin/users/one}]

    incr file_count
}

if {$file_count!=0} {
    append page_content "$file_html"
} else {
    append page_content "<tr><td>&nbsp; No files available in this group. &nbsp;</td></tr>"
}

append page_content "
</td></tr></table></td></tr></table></blockquote>

<a href=\"/admin/users/one?user_id=$owner_id\">summary page for $name</a>

[ad_admin_footer]"

# serve the page

doc_return  200 text/html $page_content


