# upload.tcl,v 1.4.2.3 2000/02/03 09:49:59 ron Exp
# This script allows a user to upload a file with a title
# and attach that file to another table/id in acs

ad_page_contract {
    This script allows a user to upload a file with a title
    and attach that file to another table/id in acs 

    @param on_which_table the table to upload to
    @param on_what_id the id in the table to upload to
    @param return_url url to return to after finished

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id upload.tcl,v 3.5.6.5 2001/01/10 18:22:50 khy Exp
} {
    {on_which_table:notnull}
    {on_what_id:notnull}
    {return_url:optional}
}


if { ![exists_and_not_null on_which_table] || \
	![exists_and_not_null on_what_id] } {
    ad_returnredirect "index.tcl?[export_ns_set_vars url]"
    return
}


set file_id [db_string sel_file_id_seq \
	"select events_fs_file_id_seq.nextVal from dual"]
db_release_unused_handles

set title "Upload a File"

doc_return  200 text/html "
[ad_header $title]
<h2> $title </h2>
[ad_context_bar_ws [list "../index.tcl" "Events Administration"] "Agenda File"]
<hr>

<form enctype=multipart/form-data method=POST action=upload-2>
[export_form_vars on_which_table on_what_id return_url]
[export_form_vars -sign file_id]
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

