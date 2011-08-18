# /file-storage/version-upload-2.tcl
#
# by aure@arsdigita.com mid-1999
#
# extended in January 2000 by randyg@arsdigita.com
# to accomodate general permission system
#
# $Id: version-upload.tcl,v 3.1 2000/03/11 07:59:48 aure Exp $

ad_page_variables {
    {return_url}
    {file_id}
    {group_id ""}
}

set db [ns_db gethandle]

set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set exception_text ""
set exception_count 0

set version_id [database_to_tcl_string $db "
    select version_id from fs_versions_latest where file_id = $file_id"]

if ![fs_check_write_p $db $user_id $version_id $group_id] {
    incr exception_count
    append exception_text "<li>You can't write into this file"
}

## return errors
if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

if { $exception_count> 0 } {
    ad_return_complaint $exception_count $exception_text
    return 0
}

set title "Upload New Version of [database_to_tcl_string $db "select file_title from fs_files where file_id=$file_id"]"

set navbar [ad_context_bar_ws [list "" [ad_parameter SystemName fs]] "Upload New Version"]

set version_id [database_to_tcl_string $db "select fs_version_id_seq.nextval from dual"]

# release the database handle

ns_db releasehandle $db

# serve the page

ns_return 200 text/html "

[ad_header $title]

<h2>$title</h2>

$navbar

<hr>
<form enctype=multipart/form-data method=POST action=version-upload-2>

<form  method=POST action=version-upload-2>
[export_form_vars file_id version_id return_url]

<table>
<tr>
<td align=right>Filename: </td>
<td>
<input type=file name=upload_file size=20>
</td>
</tr>
<tr>
<td>&nbsp;</td>
<td>
Use the \"Browse...\" button to locate your file, then click \"Open\".
</td>
</tr>

<tr>
<td align=right>
Version Notes:</td>
<td><input type=text size=50  name=version_description></td>
</tr>

<tr>
<td></td>
<td><input type=submit value=\"Update\">
</td>
</tr>
</table>

</form>

[ad_footer [fs_system_owner]]"


