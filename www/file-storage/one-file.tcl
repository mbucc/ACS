# /file-storage/one-file.tcl
#
# by aure@arsdigita.com July 1999 
# (rewritten by philg@mit.edu) 
# philg@mit.edu added commentability on December 19, 1999
#
# modified by randyg@arsdigita.com January, 2000
#
# summary of one file, with options to download, edit properties, or
# upload new version
#
# $Id: one-file.tcl,v 3.5.2.9 2000/04/28 15:10:28 carsten Exp $

ad_page_variables {
    {file_id}
    {group_id ""}
    {owner_id ""}
    {source ""}
}

set local_user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set exception_text ""
set exception_count 0

set latest_version_id [database_to_tcl_string $db "
    select version_id from fs_versions_latest where file_id = $file_id"]

if { ![fs_check_read_p $db $local_user_id $latest_version_id $group_id]} {
    incr exception_count
    append exception_text "<li>You can't read this file"
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
           fsvl.url,
           u.first_names || ' ' || u.last_name as owner_name,
           ad_general_permissions.user_has_row_permission_p ($local_user_id, 'read', fsvl.version_id, '$on_which_table' ) as public_read_p
    from   fs_files fsf1,
           fs_files fsf2,
           fs_versions fsv,
           fs_versions_latest fsvl,
           users u
    where  fsf1.file_id = $file_id
    and    fsf1.parent_id = fsf2.file_id (+)
    and    fsf1.file_id = fsvl.file_id
    and    ad_general_permissions.user_has_row_permission_p ($local_user_id, 'read', fsvl.version_id, '$on_which_table' ) = 't'
    and    fsf1.owner_id = u.user_id
    group by fsf1.file_title,
           fsf2.file_title,
           fsf1.folder_p,
           fsf1.parent_id,
           fsvl.url,
           u.first_names,
           u.last_name,
           ad_general_permissions.user_has_row_permission_p ($local_user_id, 'read', fsvl.version_id, '$on_which_table' )"

set selection [ns_db 0or1row $db $file_info_query]
if [empty_string_p $selection] {
    ad_return_error "File not found" "Could not find file $file_id; it may have been deleted."
    return
}
 
set_variables_after_query

if { $folder_p == "t" } {
    # we got here by mistake, push them out into the right place 
    # (this shouldn't happen!)
    ns_log Error "User was sent to /file-storage/one-file.tcl to view a FOLDER (#$file_id)"
    ad_returnredirect "one-folder?[export_entire_form_as_url_vars]"
    return
}

if { ![empty_string_p $group_id] } {
    set group_name [database_to_tcl_string $db "
    select group_name 
    from   user_groups 
    where  group_id=$group_id"]

    set tree_name "$group_name document tree"
} else {
    if {$public_read_p == "t"} {
	set tree_name "Shared [ad_system_name] document tree"
    } else {
	set tree_name "Your personal document tree"
    }
}


set object_type File

set title $file_title

if {[empty_string_p $parent_title]} {
    set parent_title "Root (Top Level)"
}


# the navbar is determined by where they just came from

switch $source {
    "personal" {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "personal" "Personal document tree"] "One File"]
}
    "group" { 
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "group?group_id=$group_id" "$group_name document tree"] "One File"]
    }
    "public_individual" {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "public-one-person?[export_url_vars owner_id]" "$owner_name's publically accessible files"] "One File"]
    }
    "public_group" {
	set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] [list "public-one-group?[export_url_vars group_id]" "$group_name publically accessible files"]  "One File"]
    }
    default {
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
<hr>"

set action_list [list]


if {[fs_check_edit_p $db $local_user_id $latest_version_id $group_id]} {
    if [empty_string_p $url] {
        lappend action_list "<a href=\"version-upload?[export_url_vars return_url file_id]\">upload new version</a>"
        lappend action_list "<a href=\"file-edit?[export_url_vars group_id file_id return_url]\">edit file</a>"
        lappend action_list "<a href=\"file-delete?[export_url_vars group_id file_id return_url source object_type]\">delete this file (including all versions)</a>"
    } else {
        lappend action_list "<a href=\"url-delete?[export_url_vars group_id file_id return_url source]\">delete</a>"
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
set selection [ns_db select $db "
    select fsv.version_id,
           fsv.version_description,
           fsv.client_file_name,
           round (fsv.n_bytes / 1024) as n_kbytes,
           u.first_names || ' ' || u.last_name as creator_name,
           to_char ( fsv.creation_date, '[fs_date_picture]' ) as creation_date,
           nvl (fsv.file_type, upper (fsv.file_extension) || ' File') as file_type,
           fsv.author_id,
           decode (ad_general_permissions.user_has_row_permission_p ($local_user_id, 'read', fsv.version_id, '$on_which_table'), 't', 1, 0) as read_p,
           decode (ad_general_permissions.user_has_row_permission_p ($local_user_id, 'write', fsv.version_id, '$on_which_table'), 't', 1, 0) as write_p,
           decode (ad_general_permissions.user_has_row_permission_p ($local_user_id, 'administer', fsv.version_id, '$on_which_table'), 't', 1, 0) as administer_p
    from   fs_versions fsv,
           users u
    where  fsv.file_id = $file_id
    and    fsv.author_id = u.user_id
    order by fsv.creation_date desc"]

set font "<font face=arial,helvetica>"

set header_color [ad_parameter HeaderColor fs]

if [empty_string_p $url] {
    append page_content "
    <table border=1 bgcolor=white  cellpadding=0 cellspacing=0>
    <tr>
    <td><table bgcolor=white cellspacing=1 border=0 cellpadding=2>
        <tr>
        <td colspan=8 bgcolor=#666666>$font &nbsp;<font color=white> 
         All Versions of $file_title</td>
        </tr>
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

    while {[ns_db getrow $db $selection]} {
        set_variables_after_query
	incr version_count
	set page_name "$file_title: version [expr $n_versions - $version_count + 1]"

        regexp {.*\\([^\\]+)} $client_file_name match client_file_name
	regsub -all {[^-_.0-9a-zA-Z]+} $client_file_name "_" pretty_file_name

	set permissions_list [list]

	if {$read_p > 0} {
	    append version_html "
	    <tr>
	    <td valign=top>&nbsp;<a href=\"download/$pretty_file_name?[export_url_vars version_id]\">$graphic</a></td>
	    <td valign=top>$font <a href=\"download/$pretty_file_name?[export_url_vars version_id]\">$client_file_name</a> &nbsp;</td>"
	    lappend permissions_list "<a href=\"download/$pretty_file_name?[export_url_vars version_id]\">read</a>"
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

	if {![empty_string_p $n_kbytes]} {
	    set n_kbytes "$n_kbytes KB"
	}

	if { [llength $permissions_list] > 0} {
	    set permissions_string "[join $permissions_list " | "]"
	} else {
	    set permissions_string "None"
	}

	append version_html "
	    <td valign=top>$font <a href=/shared/community-member?user_id=$author_id>$creator_name</a></td>
	    <td align=right valign=top>$font $n_kbytes</td>
	    <td valign=top align=center>$font [fs_pretty_file_type $file_type]</td>
	    <td valign=top>$font $creation_date</td>
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
	where fs_files.file_id = $file_id and fs_files.owner_id = $local_user_id"

    if {[database_to_tcl_string $db $query] > 0} {
	set comments_read_p 1
	set comments_write_p 1
    } else {
	set comments_read_p 1
	set comments_write_p [ad_user_has_row_permission_p $db $local_user_id \
	    "comment" $latest_version_id $on_which_table]
    }
}

if {$comments_read_p} {
    append page_content "
	[ad_general_comments_list $db $file_id "fs_files" $file_title fs "" "" {} \
	 $comments_write_p]"
}


append page_content "
</ul>

[ad_footer [fs_system_owner]]"

# release the database handle

ns_db releasehandle $db

# serve the page

ns_return 200 text/html $page_content
