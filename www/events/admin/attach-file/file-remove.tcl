ad_page_contract {
    
    @param file_id The file being removed.
    @param return_url What url to be go back to when done.

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id file-remove.tcl,v 3.4.6.6 2000/09/22 01:37:40 kevin Exp

} {
    {file_id:integer}
    return_url
}

set file_title [db_string "events_file_title" "
select file_title from events_file_storage
where file_id=:file_id"]

db_release_unused_handles

set title "Remove a File"

doc_return  200 text/html "
[ad_header $title]
<h2> $title </h2>
[ad_context_bar_ws [list "../index.tcl" "Events Administration"] "Agenda File"]
<hr>
Are you sure you want to remove the file, <i>$file_title</i>?
<p>
<form method=post action=file-remove-2>
[export_form_vars file_id return_url]
<center>
<input type=submit value=\"Remove file\">
</center>
</form>
[ad_footer]"