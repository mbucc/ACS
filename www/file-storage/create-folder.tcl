# /file-storage/create-folder.tcl

ad_page_contract {
    this file allows a user to select a title and location for
    a new folder

    @author aure@arsdigita.com
    @creation-date July, 1999
    @cvs-id create-folder.tcl,v 3.7.2.5 2001/01/10 18:49:02 khy Exp

    modified by randyg@arsdigita.com, January, 2000 to use the general
    permissions module
} {
    {return_url}
    {group_id ""}
    {public_p ""}
    {this_folder ""}
}

set user_id [ad_maybe_redirect_for_registration]

set title "Create New Folder"

# Determine if we are uploading to a Group or to our personal area
# this is based if no group_id was sent - then we are uploading
# to our personal area - otherwise the default group defined by group_id

set exception_text ""
set exception_count 0

if { $public_p == "t" && ![ad_parameter PublicDocumentTreeP fs] } {
    append exception_text "
        <li>[ad_system_name] does not support a public directory tree."
    incr exception_count
}



if { ![empty_string_p $group_id] } {

    set group_name [db_string unused "
	select group_name 
	from   user_groups
	where  group_id = :group_id"]

    # we are in the group tree

    if { ![ad_user_group_member $group_id $user_id] } {

	append exception_text "
	    <li>You are not a member of group <cite>$group_name</cite>\n"

	incr exception_count

    } else {

	set navbar [ad_context_bar_ws \
		[list "" [ad_parameter SystemName fs]] \
		[list $return_url "$group_name document tree"] \
		$title]

    }

    set public_p "f"

} elseif { $public_p == "t" } { 

    # we are in the public document tree

    set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] $title]
    set group_id ""

} else {

    # we are in the personal document tree

    set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]]\
	                          [list "private-one-person" "Personal document tree"]\
				  $title]
    set group_id ""
    set public_p "f"

}

if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set file_id [db_string unused "select fs_file_id_seq.nextval from dual"]
set version_id [db_string unused "select fs_version_id_seq.nextval from dual"]

set page_content "[ad_header $title]

<h2>$title</h2>

$navbar

<hr align=left>
<form  method=POST action=create-folder-2>
[export_form_vars -sign file_id version_id]
[export_form_vars return_url group_id public_p]

<table>
<tr>
<td align=right>Folder Name: </td>
<td><input size=30 name=file_title></td>
</tr>

<tr>
<td align=right>Location:</td>
<td>[fs_folder_def_selection $user_id $group_id $public_p "" $this_folder]</td>
</tr>

<tr>
<td>&nbsp;</td>
<td><input type=submit value=\"Create\">
</td>
</tr>

</table>

</form>

[ad_footer [fs_system_owner]]"

# serve the page

doc_return  200 text/html $page_content
