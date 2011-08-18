# upload.tcl,v 1.4.2.3 2000/02/03 09:49:59 ron Exp
# This script allows a user to upload a file with a title
# and attach that file to another table/id in acs

set_form_variables 0
# on_which_table on_what_id return_url

if { ![exists_and_not_null on_which_table] || \
	![exists_and_not_null on_what_id] } {
    ad_returnredirect "index.tcl?[export_ns_set_vars url]"
    return
}

set db [ns_db gethandle]
set file_id [database_to_tcl_string $db \
	"select events_fs_file_id_seq.nextVal from dual"]
ns_db releasehandle $db

set title "Upload a File"

ReturnHeaders

ns_write "
[ad_header $title]
<h2> $title </h2>
[ad_context_bar_ws [list "../index.tcl" "Events Administration"] "Agenda File"]
<hr>

<form enctype=multipart/form-data method=POST action=upload-2.tcl>
[export_form_vars on_which_table on_what_id return_url file_id]
<table>
<tr>
<td valign=top align=right>File: </td>
<td>
<input type=file name=upload_file size=30><br>
Use the \"Browse...\" button to locate your File, then click \"Open\".
</td>
</tr>
<tr>
  <td valign=top align=right>Title: </td>
  <td><input type=text name=file_title size=45> </td>
</tr>
<tr>
<td></td>
<td><input type=submit value=\"Upload\">
</td>
</tr>
</table>

</form>

[ad_footer]
"

