# /admin/file-storage/group.tcl
#
# by aure@arsdigita.com, July 1999
#
# displays a group's files
#
# $Id: group.tcl,v 3.1.2.1 2000/03/17 17:42:25 aure Exp $

ad_page_variables {group_id}

set db [ns_db gethandle]

if [empty_string_p $group_id] {
    ad_return_error "Can't find group" "Can't find group #$group_id"
    return
}

set group_name [database_to_tcl_string_or_null $db "
    select group_name from user_groups where group_id = $group_id"]

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
           lpad('x',depth,'x') as spaces,
           to_char(v.creation_date,'MM/DD/YY HH24:MI') as creation_date,
           round(n_bytes/1024) as n_kbytes, 
           nvl(file_type,upper(file_extension)||' File') as file_type,
           first_names||' '||last_name as owner_name, 
           fs_files.deleted_p, 
           owner_id
    from   fs_files, 
           fs_versions_latest v, 
           users
    where  group_id = $group_id
    and    owner_id = users.user_id
    and    fs_files.file_id = v.file_id(+)
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
    regsub -all x $spaces "<img src=\"/graphics/file-storage/spacer.gif\" width=24 height=1>" spaces
    set spaces [string trim $spaces]

    if {$folder_p=="t"} {

	append file_html "
	<tr>
	<td valign=top>&nbsp; ${spaces}$font<a href=info?[export_url_vars file_id group_id]><img border=0 src=/graphics/file-storage/ftv2folderopen.gif align=top></a>
	<a href=info?[export_url_vars file_id group_id]>$file_title</a></td>
	<td align=right></td>
	<td>&nbsp;</td>
	<td>$font &nbsp; File Folder &nbsp;</td>
	<td>&nbsp;</td>
	</tr>\n"
    
    } else {

	append file_html "
	<tr>
	<td valign=top>&nbsp; ${spaces}$font<a href=info?[export_url_vars file_id group_id return_url]><img \n border=0 src=/graphics/file-storage/ftv2doc.gif align=top></a>
	<a href=info?[export_url_vars file_id group_id return_url]>$file_title</a>&nbsp;</td>
	<td>$font<a href=/shared/community-member?[export_url_vars return_url]&user_id=$owner_id>$owner_name</a>&nbsp;</td>
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

    append page_content "<tr><td>&nbsp; No files available in this group. &nbsp;</td></tr>"

}

append page_content "
</td></tr></table></td></tr></table>

</blockquote>

</form>
[ad_admin_footer]"

# release the database handle

ns_db releasehandle $db 

# serve the page

ns_return 200 text/html $page_content 









