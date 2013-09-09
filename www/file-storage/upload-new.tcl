# /file-storage/upload-new.tcl

ad_page_contract {
    Serve the user a form to upload a new file or URL

    @author aure@arsdigita.com
    @creation-date July 1999
    @cvs_id upload-new.tcl,v 3.6.6.6 2001/01/10 18:46:45 khy Exp

    modified by randyg@arsdigita.com, January 2000 to use the general permisisons system
} {
    return_url
    {group_id ""}
    {public_p ""}
    {this_folder ""}
}

set user_id [ad_maybe_redirect_for_registration]

set title "Upload New File/URL"

# Determine if we are uploading to a Group, the public area, or personal area

# if public_p = 't', we are uploading to the public area
# if  a group_id was sent - then we are uploading to a group defined
#           by group_id
# otherwise, to our personal area

set exception_text ""
set exception_count 0

if {$public_p == "t" && ![ad_parameter PublicDocumentTreeP fs]} {
    incr exception_count
    append exception_text "
        [ad_system_name] does not support a public directory tree."
}

if { ![empty_string_p $group_id]} {

    set group_name [db_string group_name_get {
	select group_name 
	from   user_groups 
        where  group_id = :group_id } ]

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
 
    # we are in the public tree

    set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] $title]
    set group_id ""

} else  {

    # we are in the personal tree

    set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]]\
	                          [list "private-one-person" "Personal document tree"]\
				  $title]
    set group_id ""
    set public_p "f"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

# get the next sequence values for double click protection

set file_id    [db_string unused "
    select fs_file_id_seq.nextval from dual"]
set version_id [db_string unused "
    select fs_version_id_seq.nextval from dual"]

set page_content "
[ad_header $title]

<h2>$title</h2>

$navbar

<hr align=left>

<form enctype=multipart/form-data method=POST action=upload-new-2>

[export_form_vars -sign file_id version_id]
[export_form_vars return_url group_id public_p]

<table border=0>
<tr>
<td align=right>URL: </td>
<td><input type=input name=url size=40></td>
</tr>

<tr>
<td align=right><EM>or</EM> filename: </td>
<td><input type=file name=upload_file size=20></td>
</tr>

<tr>
<td>&nbsp;</td>
<td><font size=-1>Use the \"Browse...\" button to locate your file, 
    then click \"Open\". </font></td>
</tr>

<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
</tr>

<tr>
<td align=right> Title: </td>
<td><input size=30 name=file_title></td>
</tr>

<tr>
<td valign=top align=right> Description: </td>
<td colspan=2><textarea rows=5 cols=50 name=version_description wrap></textarea></td>
</tr>

<tr>
<td align=right>Location:</td>
<td>[fs_folder_def_selection $user_id $group_id $public_p $this_folder $this_folder]</td>
</tr>

<tr>
<td></td>
<td><input type=submit value=\"Submit and Upload\">
</td>
</tr>

</table>

</form>

[ad_footer [fs_system_owner]]"

# serve the page

doc_return  200 text/html $page_content

