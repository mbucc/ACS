# /file-storage/private-one-person.tcl

ad_page_contract { 
    this file displays all files in the user's personal folder

    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs-id private-one-person.tcl,v 3.14.2.2 2000/07/21 22:05:17 mdetting Exp

    modified by randyg@arsdigita.com, January, 2000 to use the general 
    permissions module
} {
}

if [info exists user_id] {
    ad_returnredirect "public-one-person.tcl?[ns_conn query]"
}

set user_id [ad_maybe_redirect_for_registration]

set cookies [get_cookie_set]
set folders_open_p [ns_set get $cookies folders_open_p]
if [empty_string_p $folders_open_p] {
    set folders_open_p 1
}

set return_url "private-one-person"



set name_query "select first_names||' '||last_name as name 
               from   users 
               where  user_id = :user_id"
set name [db_string unused $name_query]

set title "$name's document tree"

set public_p "f"

set page_content  "
[ad_header $title ]

<h2> $title </h2>

[ad_context_bar_ws [list "" [ad_parameter SystemName fs]] "Personal document tree"]

<hr align=left>

<ul>
   <li><a href=upload-new?[export_url_vars return_url public_p]>Add a URL / Upload a new file</a>
   <li><a href=create-folder?[export_url_vars return_url public_p]>Create New Folder</a> (for storing personal files)

   <form action=search method=post>
"

if { [ad_parameter UseIntermediaP fs 0] } {
    append page_content "<li> Search file names and contents for: "
} else {
    append page_content "<li> Search file names for: "
}

append page_content "<input name=search_text type=text size=20>[export_form_vars return_url]<input type=submit value=Search></form>

</ul>
<blockquote>"

# get the user's files from the database and parse the output to 
# reflect the folder stucture

set sorted_query "
    select fsf.file_id,
           fsf.file_title,
           fsvl.url,
           fsf.folder_p,
           fsf.depth * 24 as n_pixels_in,
           round ( fsvl.n_bytes / 1024 ) as n_kbytes,
           n_bytes,
           to_char ( fsvl.creation_date, '[fs_date_picture]' ) as creation_date,
           nvl ( fsvl.file_type, upper ( fsvl.file_extension ) || ' File' ) as file_type,
           fsvl.client_file_name, 
           fsvl.url,
           fsvl.version_id
    from   fs_files fsf,
           fs_versions_latest fsvl
    where  fsf.file_id = fsvl.file_id
    and    deleted_p = 'f'
    and    fsf.owner_id = :user_id
    and    fsf.group_id is null
    and    (fsf.public_p = 'f' or fsf.public_p is null)
    order by fsf.sort_key"

set file_html ""
set group_id ""
set file_count 0

set font "<nobr>[ad_parameter FileInfoDisplayFontTag fs]"

set header_color [ad_parameter HeaderColor fs]

# we start with an outer table to get little white lines in 
# between the elements 

append page_content "
<li>
[fs_folder_box $user_id [fs_private_individual_option]]
</li>"

append page_content "
<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
<tr>
<td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
[fs_header_row_for_files -title "Your personal document tree"]
"

db_foreach file_list $sorted_query {
    append file_html [fs_row_for_one_file -n_pixels_in $n_pixels_in \
	    -file_id $file_id \
	    -folder_p $folder_p -client_file_name $client_file_name \
	    -n_kbytes $n_kbytes -n_bytes $n_bytes -file_title $file_title -url $url -creation_date $creation_date \
	    -version_id $version_id -file_type $file_type \
	    -export_url_vars "[export_url_vars file_id group_id]&source=private_individual"]
        
    incr file_count
}

if {$file_count!=0} {
    append page_content $file_html
} else {
    append page_content "
        <tr>
        <td>You don't have any files stored in the database. </td>
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

# Serve the page.
# Because we are called without parameters, we add a Pragma: no-cache.

ns_set put [ns_conn outputheaders] "Pragma" "no-cache"
ReturnHeaders
ns_write $page_content
