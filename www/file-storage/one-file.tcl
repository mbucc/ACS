# /www/file-storage/one-file.tcl
ad_page_contract {
    Display a summary of one file, with options to download, edit properties, or
    upload new version.

    @author aure@arsdigita.com
    @creation-date July 1999 
    @cvs-id one-file.tcl,v 3.21.2.5 2000/09/22 01:37:48 kevin Exp
    @param file_id The id of the requested file.
    @param group_id The id of the group that owns the file.
    @param owner_id An id for the owner of the file.
    @param source Where the file is stored.
    @param view Which versions of the file should be viewed.  Valid values are "latest" and "all."
} {
    file_id:integer
    {group_id:integer ""}
    {owner_id:integer ""}
    {source ""}
    {view "latest"}
} 

set local_user_id [ad_maybe_redirect_for_registration]

set exception_text ""
set exception_count 0

if { [db_string num_files {
    select count(*) from fs_files where file_id = :file_id
} ] == 0 } {
    incr exception_count
    append exception_text "<li>The given file ID does not exist"
} else {
    set latest_version_id [db_string fs_latest_version {
        select version_id from fs_versions_latest where file_id = :file_id}]

    if { ![fs_check_read_p $local_user_id $latest_version_id $group_id]} {
	incr exception_count
	append exception_text "<li>You can't read this file"
    }
}

if { ![empty_string_p $group_id] && [db_string fs_group_count {
    select count(*) from user_groups where group_id=:group_id
}] == 0 } {
    incr exception_count
    append exception_text "<li>The given group ID does not exist"
}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set on_which_table "FS_VERSIONS"

set file_info_query "
    select count ( fsv.version_id ) as n_versions,
           fsf1.file_title,
           fsf2.file_title as parent_title,
           fsf1.folder_p,
           fsf1.parent_id,
	   fsf1.public_p,
	   fsf1.owner_id,
	   fsf1.group_id,
           fsf1.deleted_p,
	   fsvl.url,
           u.first_names || ' ' || u.last_name as owner_name
    from   fs_files fsf1,
           fs_files fsf2,
           fs_versions fsv,
           fs_versions_latest fsvl,
           users u
    where  fsf1.file_id = :file_id
    and    fsf1.parent_id = fsf2.file_id (+)
    and    fsf1.file_id = fsvl.file_id
    and    ad_general_permissions.user_has_row_permission_p (:local_user_id, 'read', fsvl.version_id, :on_which_table) = 't'
    and    fsf1.owner_id = u.user_id
    group by fsf1.file_title,
           fsf2.file_title,
           fsf1.folder_p,
           fsf1.parent_id,
	   fsf1.public_p,
	   fsf1.owner_id,
	   fsf1.group_id,
           fsf1.deleted_p,
           fsvl.url,
           u.first_names,
           u.last_name"

if { [db_0or1row file_info $file_info_query]==0 } {
    ad_return_error "File not found" "Could not find file $file_id; it may have been deleted."
    return
}
 
if { $deleted_p == "t" } {
    set owner [db_string fs_getemail {
	select '<a href=mailto:' || email || '>' || first_names || ' ' || last_name || '</a>'
	from users where user_id = :owner_id} ]
    ad_return_error "File has been deleted" "The file $file_id has been marked as deleted. You can contact the owner
    of the file ($owner), if you want."
    return
}

if { $folder_p == "t" } {
    # we got here by mistake, push them out into the right place 
    # (this shouldn't happen!)
    ns_log Error "User was sent to /file-storage/one-file.tcl to view a FOLDER (#$file_id)"
    ad_returnredirect "one-folder?[export_entire_form_as_url_vars]"
    return
}

set object_type File

set title $file_title

if {[empty_string_p $parent_title]} {
    set parent_title "Root (Top Level)"
}

if { [empty_string_p $source] } {
    set source [fs_guess_source $public_p $owner_id $group_id $local_user_id]
}

# the navbar is determined by where they just came from

switch $source {
    "private_individual" {
	set tree_name "Your personal document tree"

	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "private-one-person" $tree_name] "One File"]
    }
    "private_group" { 
	db_1row group_name "
	select group_name from user_groups where group_id=:group_id"
	set tree_name "$group_name group document tree"

	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "private-one-group?[export_url_vars group_id]" $tree_name] "One File"]
    }
    "public_individual" {
	set tree_name "$owner_name's document tree"

	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "all-public" "Publically accessible files"] [list "public-one-person?user_id=$owner_id" $tree_name] "One File"]
    }
    "public_group" {
	db_1row group_name "
	select group_name from user_groups where group_id=:group_id"
	set tree_name "$group_name group public document tree"

	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "all-public" "Publically accessible files"] [list "public-one-group?[export_url_vars group_id]" $tree_name] "One File"]
    }
    default {
	set tree_name "Shared [ad_system_name] document tree"
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] "One File"]
    }
}

# We use return_url to create links to other pages that should
# return back here.
#
set return_url "[ns_conn url]?[ns_conn query]"

# We pass the title of this file to /gp/administer-permissions.tcl as
# object_name.
#
set object_name $title

set page_content "
[ad_header $title ]

<h2> $title </h2>

$navbar
<hr align=left>"

set action_list [list]

set query "
    select count(*) from fs_versions 
    where file_id=:file_id and not superseded_by_id is null"

if {[empty_string_p $url] && [db_string num_versions $query] > 0}  {
    if {$view == "all"} {
	lappend action_list "<a href=\"one-file?[export_ns_set_vars url view]&view=latest\">show only latest version</a>"
    } else {
	lappend action_list "<a href=\"one-file?[export_ns_set_vars url view]&view=all\">show all versions</a>"
    }
}

if {[fs_check_edit_p $local_user_id $latest_version_id $group_id]} {
    if [empty_string_p $url] {
        lappend action_list "<a href=\"version-upload?[export_url_vars return_url file_id]\">upload new version</a>"
        lappend action_list "<a href=\"file-edit?[export_url_vars group_id file_id return_url]\">edit file</a>"
        lappend action_list "<a href=\"file-delete?[export_url_vars group_id file_id return_url source object_type]\">delete this file (including all versions)</a>"
    } else {
        lappend action_list "<a href=\"url-delete?[export_url_vars owner_id group_id file_id return_url source]\">delete</a>"      
	lappend action_list "<a href=\"url-edit?[export_url_vars group_id file_id return_url source]\">edit</a>"
    }
}

append page_content "
<ul>
<li> Title: $file_title
<li> Owner: $owner_name
<li> Located in: $tree_name / $parent_title "

if { [llength $action_list] > 0 } {
    append page_content "
    <p>
    <li>Actions:  [join $action_list " | "]\n"
}

append page_content "
</ul>
<blockquote>"

set version_html ""
set version_count 0

# this query replaces the monster that follows.
# its purpose is to extract all versions of this file (with some extra information)
# and also with permission information

if {$view == "all"} {
    set fs_table "fs_versions"
    set table_title "All Versions of $file_title"
} else {
    set fs_table "fs_versions_latest"
    set table_title "Latest Version of $file_title"
}

set sql "
    select fsv.version_id,
           fsv.version_description,
           fsv.client_file_name,
           round (fsv.n_bytes / 1024) as n_kbytes,
           n_bytes,
           u.first_names || ' ' || u.last_name as creator_name,
           to_char ( fsv.creation_date, '[fs_date_picture]' ) as pretty_creation_date,
           nvl (fsv.file_type, upper (fsv.file_extension) || ' File') as file_type,
           fsv.author_id,
           decode (ad_general_permissions.user_has_row_permission_p ($local_user_id, 'read', fsv.version_id, '$on_which_table'), 't', 1, 0) as read_p,
           decode (ad_general_permissions.user_has_row_permission_p ($local_user_id, 'write', fsv.version_id, '$on_which_table'), 't', 1, 0) as write_p,
           decode (ad_general_permissions.user_has_row_permission_p ($local_user_id, 'administer', fsv.version_id, '$on_which_table'), 't', 1, 0) as administer_p
    from   $fs_table fsv,
           users u
    where  fsv.file_id = $file_id
    and    fsv.author_id = u.user_id
    order by fsv.creation_date desc"

set font "<font face=arial,helvetica>"

set header_color [ad_parameter HeaderColor fs]

if [empty_string_p $url] {
    append page_content "
    <table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
    <tr>
    <td><table bgcolor=white cellspacing=1 border=0 cellpadding=2>
        <tr>
        <td colspan=8 bgcolor=#666666>$font &nbsp;<font color=white>
         $table_title
        </td></tr>
        <tr>
        <td colspan=2 bgcolor=$header_color>$font &nbsp; Name &nbsp;</td>
        <td bgcolor=$header_color>$font &nbsp; Author &nbsp;</td>
        <td bgcolor=$header_color align=right>$font &nbsp; Size &nbsp;</td>
        <td bgcolor=$header_color>$font &nbsp; Type &nbsp;</td>
        <td bgcolor=$header_color>$font &nbsp; Modified &nbsp;</td>
        <td bgcolor=$header_color>$font &nbsp; Version Notes &nbsp;</td>
        <td bgcolor=$header_color>$font &nbsp; Permissions &nbsp;</td>
        </tr>" 

    set graphic "<img border=0 align=top src=/graphics/file-storage/ftv2doc.gif>"

    db_foreach file_info $sql {
	incr version_count
	set page_name "$file_title: version [expr $n_versions - $version_count + 1]"

        regexp {.*\\([^\\]+)} $client_file_name match client_file_name
	regsub -all {[^-_.0-9a-zA-Z]+} $client_file_name "_" pretty_file_name

	set permissions_list [list]

	if {$read_p > 0} {
	    append version_html "
	    <tr>
	    <td valign=top>&nbsp;<a href=\"download?version_id=[ns_urlencode $version_id]\">$graphic</a></td>
	    <td valign=top>$font <a href=\"download?version_id=[ns_urlencode $version_id]\">$client_file_name</a> &nbsp;</td>"
	    lappend permissions_list "<a href=\"download/[ns_urlencode $version_id]/$pretty_file_name\">read</a>"
	} else {
	    append version_html "
	    <tr><td valign=top>&nbsp; $font $graphic</td>
	    <td valign=top>$client_file_name &nbsp;</td>"
	}

	if {$write_p > 0} {
	    lappend permissions_list "<a href=\"version-upload?[export_url_vars return_url file_id]\">write</a>"
	}

	if {$administer_p > 0} {
	    lappend permissions_list "<a href=\"/gp/administer-permissions?on_what_id=$latest_version_id&[export_url_vars on_which_table return_url object_name]\">administer</a>"
	}

	if {![empty_string_p $n_kbytes] } {

	    if { $n_kbytes == 0 } {
		set size_string "$n_bytes bytes"
	    } else {
		set size_string "$n_kbytes KB"
	    }
	} 

	if { [llength $permissions_list] > 0} {
	    set permissions_string "[join $permissions_list " | "]"
	} else {
	    set permissions_string "None"
	}

	append version_html "
	    <td valign=top>$font [ad_present_user $author_id $creator_name]</td>
	    <td align=right valign=top>$font $size_string</td>
	    <td valign=top align=center>$font [fs_pretty_file_type $file_type]</td>
	    <td valign=top>$font $pretty_creation_date</td>
	    <td valign=top>$font $version_description</td>
	    <td valign=top align=center>$font $permissions_string </td>
	    </tr>\n"
    }

    append page_content "$version_html</table>"

} else {
    append page_content "<a href=\"$url\">$url</A>"
}

append page_content "</td></tr></table></blockquote>"

set comments_read_p 0
set comments_write_p 0

if {[ad_parameter CommentPermissionsP gp]} {
    set query "
	select count(fs_files.file_id) from fs_files 
	where fs_files.file_id = :file_id and fs_files.owner_id = :local_user_id"

    if {[db_string counts $query] > 0} {
	set comments_read_p 1
	set comments_write_p 1
    } else {
	set comments_read_p 1
	set comments_write_p [ad_user_has_permission_p $local_user_id \
	    "comment" $latest_version_id $on_which_table]
    }
}

if {$comments_read_p} {
    append page_content "
	[ad_general_comments_list $file_id "fs_files" $file_title fs "" "" {} \
	 $comments_write_p]"
}

append page_content "
</ul>

[ad_footer [fs_system_owner]]"

# release the database handle

db_release_unused_handles

# serve the page

doc_return  200 text/html $page_content
