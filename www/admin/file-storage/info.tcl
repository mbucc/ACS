# /admin/file-storage/info.tcl

ad_page_contract {
    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs-id info.tcl,v 3.6.2.4 2000/09/22 01:35:15 kevin Exp
} {
    file_id:integer
    {group_id ""}
    {owner_id ""}
}

set return_url "info?[ns_conn query]"
set graphic "<img border=0 src=/graphics/file-storage/ftv2doc.gif align=top>"

set exception_text ""
set exception_count 0

if {![info exists file_id] || [empty_string_p $file_id] } {
    ad_returnredirect ""
}

set file_info_query "
select count(fs_versions.version_id) as n_versions, 
       f1.file_title, 
       f2.file_title as parent_title, 
       f1.folder_p, 
       f1.parent_id, 
       fs_versions_latest.url, 
       first_names || ' ' || last_name as owner_name, 
       f1.public_p
from   fs_files f1, 
       fs_files f2, 
       fs_versions_latest, 
       users, 
       general_permissions gp, fs_versions
where  f1.file_id = $file_id
and    f1.parent_id = f2.file_id(+)
and    fs_versions_latest.version_id = gp.on_what_id
and    upper(gp.on_which_table) = 'FS_VERSIONS'
and    fs_versions_latest.file_id = f1.file_id
and    f1.file_id = fs_versions.file_id
and    f1.owner_id=users.user_id
group by f1.file_title, f2.file_title, f1.folder_p, f1.parent_id, fs_versions_latest.url, first_names, last_name, f1.public_p"

if { [db_0or1row file_list $file_info_query]==0 } {
    ad_return_error "File not found" "Could not find file $file_id; it may have been deleted.
<pre>$file_info_query</pre>"
    return
}

if {$folder_p=="t"} {
    set object_type "Folder"
} else {
    set object_type "File"
}

if { [info exists group_id] && ![empty_string_p $group_id]} {
    set group_name [db_string unused "
    select group_name 
    from   user_groups 
    where  group_id=$group_id"]

    set tree_name "$group_name document tree"
} else {
    if {$public_p == "t"} {
	set tree_name "Shared [ad_system_name] document tree"
    } else {
	set tree_name "Your personal document tree"
    }
}

set title "$file_title"

if {[empty_string_p $parent_title]} {
    set parent_title "Root (Top Level)"
}

# the navbar is determined by where they just came from
if ![info exists source] {
    set source ""
}

switch $source {
    "personal" {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]]\
		                      [list "personal" "Personal document tree"]\
				      "$owner_name's Files"]
}
    "group" { 
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]]\
		                      [list "group?group_id=$group_id" "$group_name document tree"]\ 
	                              "$owner_name's Files"]
    }
    "public_individual" {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]]\
		                      [list "public-one-person?[export_url_vars owner_id]" "$owner_name's publically accessible files"] 
	                              "$owner_name's Files"]
    }
    "public_group" {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]]\
		                      [list "public-one-group?[export_url_vars group_id]" "$group_name publically accessible files"]  
	                              "$owner_name's Files"]
    }
    default {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] "$owner_name's Files"]
    }
}

set page_content  "

[ad_header $title ]

<h2> $title </h2>
$navbar
<hr>

<ul>
<li> $object_type Title: $file_title
<li> Owner: $owner_name
<li> Located in: $tree_name / $parent_title
<li> <a href=\"file-delete?file_id=$file_id&[export_url_vars object_type return_url]\">Delete File</a>
<li> <a href=\"file-edit?file_id=$file_id&[export_url_vars object_type public_p return_url]\">Edit File</a>
</ul>
<blockquote>
"

set version_html ""
set version_count 0

set bind_vars [ad_tcl_vars_to_ns_set file_id]

set sql_query "
    select version_id, 
           version_description, 
           client_file_name,
           round(n_bytes/1024) as n_kbytes, 
           first_names||' '||last_name as creator_name,
           to_char(creation_date,'[fs_date_picture]') as pretty_creation_date,
           nvl(file_type,upper(file_extension)||' File') as file_type,
           author_id
    from   fs_versions, 
           users
    where  file_id = :file_id
    and    author_id=users.user_id
    and    fs_versions.file_id = file_id
    order by pretty_creation_date desc"

set font "<nobr><font face=arial,helvetica size=-1>"

set header_color [ad_parameter HeaderColor fs]

if [empty_string_p $url] {
    append page_content "
    <table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
    <tr>
    <td><table bgcolor=white cellspacing=1 border=0 cellpadding=0>
        <tr>
        <td colspan=8 bgcolor=#666666> $font &nbsp;<font color=white> 
         All Versions of $file_title</td>
        </tr>
        <tr>
        <td bgcolor=$header_color>$font &nbsp; Name &nbsp;</td>
        <td bgcolor=$header_color>$font &nbsp; Author &nbsp;</td>
        <td bgcolor=$header_color align=right>$font &nbsp; Size &nbsp;</td>
        <td bgcolor=$header_color>$font &nbsp; Type &nbsp;</td>
        <td bgcolor=$header_color>$font &nbsp; Modified &nbsp;</td>
        <td bgcolor=$header_color>$font &nbsp; Version Notes &nbsp;</td>
        <td bgcolor=$header_color>$font &nbsp; Permissions &nbsp;</td>
        <td bgcolor=$header_color>$font &nbsp</td>
        </tr>" 

    # URL vars for /gp/administer-permissions
    #
    set on_which_table FS_VERSIONS
    set return_url "[ns_conn url]?[ns_conn query]"

    db_foreach table_columns $sql_query -bind $bind_vars {
	incr version_count
	set page_name "$file_title: version [expr $n_versions - $version_count + 1]"

        regexp {.*\\([^\\]+)} $client_file_name match client_file_name

	regsub -all {[^-_.0-9a-zA-Z]+} $client_file_name "_" pretty_file_name

	append version_html "
	<tr>
	<td valign=top>&nbsp; $font<a href=\"download/$pretty_file_name?[export_url_vars version_id]\">$graphic</a>
	<a href=\"download/$pretty_file_name?[export_url_vars version_id]\">
	$client_file_name</a> &nbsp;</td>"

	# more URL vars for /gp/administer-permissions
	#
	set object_name "${file_title} ($pretty_creation_date version)"
	set on_what_id $version_id

	append version_html "
	    <td><nobr>&nbsp; <a href=/admin/users/one?user_id=$author_id>$creator_name</a> &nbsp;</td>
	    <td align=right>$font &nbsp; $n_kbytes  &nbsp;</td>
	    <td>$font &nbsp; [fs_pretty_file_type $file_type] &nbsp;</td>
	    <td>$font &nbsp; $pretty_creation_date &nbsp;</td>
	    <td>$font $version_description &nbsp;</td>
	    <td align=center>$font <a href=\"/gp/administer-permissions?[export_url_vars on_which_table on_what_id object_name return_url]\">View</a></td>
	    <td align=center>$font <a href=\"version-delete?file_id=$file_id&version_id=$version_id&return_url=[ns_urlencode $return_url]\">Delete</a> &nbsp;</td>
	    </tr>\n"
    }

    append page_content "$version_html</table>"

} else {

    append page_content "<a href=\"$url\">$url</a>"

}

append page_content "</td></tr></table></blockquote>
</ul>

[ad_admin_footer]"

# release the database handle

db_release_unused_handles

# and serve the page

doc_return  200 text/html $page_content

