# file-remove.tcl,v 1.1.2.3 2000/02/03 09:49:51 ron Exp
set_the_usual_form_variables
#file_id, return_url

set db [ns_db gethandle]
set file_title [database_to_tcl_string $db "
select file_title from events_file_storage
where file_id=$file_id"]

ns_db releasehandle $db

set title "Remove a File"

ReturnHeaders

ns_write "
[ad_header $title]
<h2> $title </h2>
[ad_context_bar_ws [list "../index.tcl" "Events Administration"] "Agenda File"]
<hr>
Are you sure you want to remove the file, <i>$file_title</i>?
<p>
<form method=post action=file-remove-2.tcl>
[export_form_vars file_id return_url]
<center>
<input type=submit value=\"Remove file\">
</center>
</form>
[ad_footer]"