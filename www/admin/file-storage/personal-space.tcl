# /admin/file-storage/personal-space.tcl
#
# by aure@arsdigita.com, July 1999
#
#
# $Id: personal-space.tcl,v 3.1.2.3 2000/03/27 14:06:15 carsten Exp $

ad_page_variables {owner_id}

set user_id $owner_id
set return_url group?[ns_conn query]


set db [ns_db gethandle ]
set sql_query "select first_names||' '||last_name as name 
               from   users 
               where  user_id=$user_id"
set name [database_to_tcl_string $db $sql_query]

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
           round(n_bytes/1024) as n_kbytes,
           to_char(fs_versions_latest.creation_date,'[fs_date_picture]') as creation_date,
           nvl(file_type,upper(file_extension)||' File') as file_type
    from   fs_files, fs_versions_latest
    where  owner_id = $user_id
    and    fs_files.file_id=fs_versions_latest.file_id(+)
    and    group_id is NULL
    and    deleted_p='f'
    order by sort_key"

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
        $font &nbsp;<font color=white> $name's files</td>
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

    if {$folder_p == "t"} {

	append file_html "
	<tr>
	<td valign=top>&nbsp; ${spacer_gif}$font
	 <a href=info?[export_url_vars file_id group_id]>
	 <img border=0 src=/graphics/file-storage/ftv2folderopen.gif align=top></a>
	 <a href=info?[export_url_vars file_id group_id]>$file_title</a></td>
	<td align=right></td>
	<td>&nbsp;</td>
	<td>$font &nbsp; File Folder &nbsp;</td>
	<td>&nbsp;</td>
	</tr>\n"    

    } else {
	append file_html "
	<tr><td valign=top>&nbsp; ${spacer_gif}$font
	<a href=info?[export_url_vars file_id group_id owner_name return_url]>
	<img \n border=0 src=/graphics/file-storage/ftv2doc.gif align=top></a>
	<a href=info?[export_url_vars file_id group_id owner_name return_url]>$file_title</a>&nbsp;</td>
	<td><a href=\"/admin/users/one?user_id=$owner_id\">$owner_name</a>&nbsp;</td>
	<td align=right>$font &nbsp; $n_kbytes KB &nbsp;</td>
	<td>$font &nbsp; [fs_pretty_file_type $file_type] &nbsp;</td>
	<td>$font &nbsp; $creation_date &nbsp;</td>
	</tr>\n"    
    }
    
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

# release the database handle

ns_db releasehandle $db 

# serve the page

ns_return 200 text/html $page_content









