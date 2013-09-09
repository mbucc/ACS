# /www/file-storage/index.tcl

ad_page_contract {
    This will show the shared document tree
    public_p = 't' and group_id is null.

    @creation-date July 1999
    @author aure@arsdigita.com
    @cvs-id index.tcl,v 3.20.2.5 2000/09/22 01:37:47 kevin Exp
} {
}

set cookies [get_cookie_set]
set folders_open_p [ns_set get $cookies folders_open_p]
if [empty_string_p $folders_open_p] {
    set folders_open_p 1
}

set user_id [ad_maybe_redirect_for_registration]

set return_url ""

if ![ad_parameter PublicDocumentTreeP fs] {
    # we are not maintaining a public site wide tree
    ad_returnredirect "private-one-person"
    return
}

if ![info exists folders_open_p] {
    set folders_open_p 1
}

set title "[ad_system_name] shared document tree"
set public_p "t"

set page_content  "
[ad_header $title]

<h2> $title </h2>

[ad_context_bar_ws [ad_parameter SystemName fs]]

<hr align=left>

<ul>
<li><a href=upload-new?[export_url_vars return_url public_p]>
    Add a URL / Upload a file</a>
<li><a href=create-folder?[export_url_vars return_url public_p]>
    Create New Folder</a> 

<form action=search method=get>"

# Display search field 

if { [ad_parameter UseIntermediaP fs 0] } {
    append page_content "<li> Search file names and contents for: "
} else {
    append page_content "<li> Search file names for: "
}

append page_content "<input name=search_text type=text size=20>[export_form_vars return_url] <input type=submit value=Search> </form>
</ul>

<blockquote>"

# get the user's files from the database and parse the 
# output to reflect the folder stucture

if {! $folders_open_p} {
   set depth_restriction "\n and depth < 1\n"
} else {
   set depth_restriction ""
}

# a file is considered public if the public_p flag is 't' and
# there are not any entries for the file in the psermissions_ug_map

# fetch all files readable by this user
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
           fsf.sort_key,
           fsvl.version_id,
           fsvl.client_file_name
    from   fs_files fsf,
           fs_versions_latest fsvl
    where  fsf.file_id = fsvl.file_id
    and    fsf.public_p = 't'
    and    group_id is NULL
    and    deleted_p = 'f' $depth_restriction
    and    (ad_general_permissions.user_has_row_permission_p ( :user_id, 'read', fsvl.version_id, 'FS_VERSIONS' ) = 't' or fsf.owner_id = :user_id )
    order by fsf.sort_key"



set file_html ""
set group_id ""

set font "<nobr>[ad_parameter FileInfoDisplayFontTag fs]"

set header_color [ad_parameter HeaderColor fs]

# we start with an outer table to get little white lines in 
# between the elements 

append page_content <li>[fs_folder_box $user_id [fs_shared_option]]</li>

append page_content "
<table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
 <tr>
 <td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
      [fs_header_row_for_files -title "[ad_system_name] shared document tree"]
" 

set rows_p 1

db_foreach list_of_files $sorted_query  {
    append file_html [fs_row_for_one_file -n_pixels_in $n_pixels_in \
	    -file_id $file_id \
	    -folder_p $folder_p -client_file_name $client_file_name \
	    -n_kbytes $n_kbytes -n_bytes $n_bytes -file_title $file_title -url $url -creation_date $creation_date \
	    -version_id $version_id -file_type $file_type \
	    -export_url_vars "[export_url_vars file_id]&source=shared"]
} if_no_rows {
    set rows_p 0
    append page_content "
    <tr>
    <td>There are no [ad_system_name] files stored in the database. </td>
    </tr>"
}

if { $rows_p } {
    append page_content "$file_html"
}

append page_content "
</table></td></tr></table></blockquote>

This system lets you keep your files on [ad_parameter SystemName],
access them from any computer connected to the internet, and
collaborate with others on file creation and modification.

<p>

[ad_footer [fs_system_owner]]"

# release the database handles
# and serve the page

 
doc_return  200 text/html $page_content 
